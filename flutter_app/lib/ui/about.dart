import 'package:bsb/app_state.dart';
import 'package:bsb/core/font_scale.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final _versionNotifier = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _lookupVersionNumber();
  }

  @override
  Widget build(BuildContext context) {
    final launchColor = Theme.of(context).colorScheme.primary;
    final textSizeNotifier = getIt.isRegistered<AppState>()
        ? getIt<AppState>().textSizeNotifier
        : ValueNotifier<double>(getIt<UserSettings>().textSize);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SafeArea(
        top: false,
        child: ValueListenableBuilder<double>(
          valueListenable: textSizeNotifier,
          builder: (context, fontSize, _) {
          final paragraphSpacing = FontScale.infoSpacing(fontSize);
          final titleStyle = TextStyle(
            fontSize: FontScale.infoTitle(fontSize),
            fontWeight: FontWeight.bold,
          );
          final contentStyle = TextStyle(fontSize: fontSize);
          return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gratitude', style: titleStyle),
              SizedBox(height: paragraphSpacing),
              Text(
                "I can't express how grateful I am to the producers of the Berean "
                "Standard Bible for releasing the BSB text to the public domain. "
                "This app would not exist otherwise. "
                "Here is their official statement: ",
                style: contentStyle,
              ),
              SizedBox(height: paragraphSpacing),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Text.rich(
                  TextSpan(
                    style: contentStyle,
                    children: [
                      const TextSpan(
                        text:
                            "The Holy Bible, Berean Standard Bible, BSB is "
                            "produced in cooperation with ",
                      ),
                      TextSpan(
                        text: "Bible Hub",
                        style: contentStyle.copyWith(
                          color: launchColor,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            _launch('https://biblehub.com/');
                          },
                      ),
                      const TextSpan(text: ", "),
                      TextSpan(
                        text: "Discovery Bible",
                        style: contentStyle.copyWith(
                          color: launchColor,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            _launch('https://discoverybible.com/');
                          },
                      ),
                      const TextSpan(text: ", "),
                      TextSpan(
                        text: "OpenBible.com",
                        style: contentStyle.copyWith(
                          color: launchColor,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            _launch('https://openbible.com/');
                          },
                      ),
                      const TextSpan(
                        text:
                            ", and the Berean Bible Translation Committee. "
                            "This text of God's Word has been ",
                      ),
                      TextSpan(
                        text: "dedicated to the public domain",
                        style: contentStyle.copyWith(
                          color: launchColor,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            _launch(
                              'https://creativecommons.org/publicdomain/zero/1.0/',
                            );
                          },
                      ),
                      const TextSpan(text: "."),
                    ],
                  ),
                ),
              ),
              SizedBox(height: paragraphSpacing),
              Text(
                "In a world where almost all publishers and Bible translators use "
                "restrictive copyrights, this gift is a breath of fresh air. "
                "God's Word should not be copyrighted.",
                style: contentStyle,
              ),
              SizedBox(height: paragraphSpacing),
              Text.rich(
                TextSpan(
                  style: contentStyle,
                  children: [
                    const TextSpan(
                      text:
                          "In the same spirit, EthnosDev also dedicates this "
                          "app to the public domain. You can find "
                          "the source code on ",
                    ),
                    TextSpan(
                      text: "GitHub",
                      style: contentStyle.copyWith(
                        color: launchColor,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          _launch('https://github.com/ethnosdev/bsb');
                        },
                    ),
                    const TextSpan(text: "."),
                  ],
                ),
              ),
              SizedBox(height: paragraphSpacing),
              Text('Privacy', style: titleStyle),
              SizedBox(height: paragraphSpacing),
              Text(
                "This app does not collect any personal information about you "
                "or share anything with third parties. Clicking a link may take "
                "you to a third party website (such as Bible Hub), which will "
                "have its own privacy policy.",
                style: contentStyle,
              ),
              SizedBox(height: paragraphSpacing),
              Text('Features', style: titleStyle),
              SizedBox(height: paragraphSpacing),
              Text(
                "Many new features are being planned. "
                "These include selection and highlighting, full-text search, "
                "and opening multiple chapters simultaneously. ",
                style: contentStyle,
              ),
              SizedBox(height: paragraphSpacing),
              Text('Feedback', style: titleStyle),
              SizedBox(height: paragraphSpacing),
              SelectableText(
                "If you have any other feature ideas or if you find a bug, "
                "please let me know by sending an email to contact@ethnos.dev.",
                style: contentStyle,
              ),
              SizedBox(height: paragraphSpacing),
              Text('App information', style: titleStyle),
              SizedBox(height: paragraphSpacing),
              Text(
                "BSB version: 3rd printing (7-31-2026)",
                style: contentStyle,
              ),
              ValueListenableBuilder<String>(
                valueListenable: _versionNotifier,
                builder: (context, version, child) {
                  return Text("App version: $version", style: contentStyle);
                },
              ),
              Text.rich(
                TextSpan(
                  style: contentStyle,
                  children: [
                    const TextSpan(text: "Developer: "),
                    TextSpan(
                      text: "EthnosDev",
                      style: contentStyle.copyWith(
                        color: launchColor,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          _launch('https://ethnos.dev/');
                        },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

  Future<void> _lookupVersionNumber() async {
    final packageInfo = await PackageInfo.fromPlatform();
    _versionNotifier.value = packageInfo.version;
  }

  Future<void> _launch(String webpage) async {
    final url = Uri.parse(webpage);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
