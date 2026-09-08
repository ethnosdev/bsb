import 'verse_element.dart';

/// Resolves multi-word translation clusters (e.g. 'vvv' words) within a verse's elements.
///
/// In the Berean Standard Bible interlinear data, multi-word phrases that translate
/// into a single English term (such as זֹרֵ֣עַ + זֶ֗רַע -> "seed-bearing") assign the
/// English translation to one anchor word and tag the companion word(s) with 'vvv'.
///
/// This function:
/// 1. Locates the anchor English word for each 'vvv' word using BSB sort adjacency
///    (and original-order proximity fallback).
/// 2. Associates all token IDs in the cluster into [OriginalWord.clusterWordIds].
/// 3. Attaches [OriginalWord.partOfTranslation] to companion words.
List<VerseElement> resolveWordClusters(List<VerseElement> elements) {
  final originalWords = elements.whereType<OriginalWord>().toList();
  final hasVvv = originalWords.any((w) => w.isVvv);
  if (!hasVvv) {
    return elements;
  }

  // Map bsbSort -> OriginalWord
  final bsbSortMap = <int, OriginalWord>{};
  for (final w in originalWords) {
    if (w.bsbSort > 0) {
      bsbSortMap[w.bsbSort] = w;
    }
  }

  bool isPlaceholder(String gloss) {
    final clean = gloss.trim();
    return clean.isEmpty ||
        clean == '-' ||
        clean == 'vvv' ||
        clean == '. . .' ||
        clean == '...' ||
        clean == '( -';
  }

  // Map each vvv token ID to its resolved anchor OriginalWord
  final vvvToAnchor = <int, OriginalWord>{};

  for (int i = 0; i < originalWords.length; i++) {
    final w = originalWords[i];
    if (!w.isVvv) continue;

    OriginalWord? anchor;

    // 1. Forward search in BSB sort order: bsbSort + 1, + 2...
    int sortForward = w.bsbSort + 1;
    while (bsbSortMap.containsKey(sortForward)) {
      final cand = bsbSortMap[sortForward]!;
      if (!isPlaceholder(cand.englishGloss)) {
        anchor = cand;
        break;
      } else if (cand.isVvv) {
        sortForward++;
      } else {
        break;
      }
    }

    // 2. Backward search in BSB sort order: bsbSort - 1, - 2...
    if (anchor == null) {
      int sortBackward = w.bsbSort - 1;
      while (bsbSortMap.containsKey(sortBackward)) {
        final cand = bsbSortMap[sortBackward]!;
        if (!isPlaceholder(cand.englishGloss)) {
          anchor = cand;
          break;
        } else if (cand.isVvv) {
          sortBackward--;
        } else {
          break;
        }
      }
    }

    // 3. Proximity fallback: search forward in original word order
    if (anchor == null) {
      for (int j = i + 1; j < originalWords.length; j++) {
        final cand = originalWords[j];
        if (!isPlaceholder(cand.englishGloss)) {
          anchor = cand;
          break;
        }
      }
    }

    // 4. Proximity fallback: search backward in original word order
    if (anchor == null) {
      for (int j = i - 1; j >= 0; j--) {
        final cand = originalWords[j];
        if (!isPlaceholder(cand.englishGloss)) {
          anchor = cand;
          break;
        }
      }
    }

    if (anchor != null) {
      vvvToAnchor[w.id] = anchor;
    }
  }

  // Build cluster ID sets: anchor word ID -> Set of all token IDs in cluster
  final clusterMap = <int, Set<int>>{};
  for (final entry in vvvToAnchor.entries) {
    final vvvId = entry.key;
    final anchor = entry.value;
    final cluster = clusterMap.putIfAbsent(anchor.id, () => {anchor.id});
    cluster.add(vvvId);
  }

  // Map each original word to its updated clustered instance
  final updatedOriginalWords = <int, OriginalWord>{};
  for (final w in originalWords) {
    if (w.isVvv) {
      final anchor = vvvToAnchor[w.id];
      if (anchor != null) {
        final fullCluster = clusterMap[anchor.id] ?? {w.id, anchor.id};
        updatedOriginalWords[w.id] = w.copyWith(
          partOfTranslation: anchor.englishGloss,
          clusterWordIds: fullCluster,
        );
      } else {
        updatedOriginalWords[w.id] = w;
      }
    } else if (clusterMap.containsKey(w.id)) {
      final fullCluster = clusterMap[w.id]!;
      updatedOriginalWords[w.id] = w.copyWith(
        clusterWordIds: fullCluster,
      );
    } else {
      updatedOriginalWords[w.id] = w;
    }
  }

  // Rebuild the elements list preserving punctuation elements
  return elements.map((element) {
    if (element is OriginalWord) {
      return updatedOriginalWords[element.id] ?? element;
    }
    return element;
  }).toList();
}
