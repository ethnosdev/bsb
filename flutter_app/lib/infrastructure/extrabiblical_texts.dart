// There are footnotes referring to the following extrabiblical texts:
//
// Jasher 79:27: 2 Timothy 3:8
// Jasher 88:63: Joshua 10:12
// Jasher 88:64: Joshua 10:13
// 1 Esdras 8:32: Ezra 8:5
// 1 Esdras 8:36: Ezra 8:10
// 1 Enoch 1:9: Jude 1:15
// 1 Enoch 13:1–11: 2 Peter 2:4
// 1 Enoch 20:1–4: 2 Peter 2:4

const validExtraBiblicalTexts = {
  'Jasher 79:27': jasher7927,
  'Jasher 88:63': jasher8863,
  'Jasher 88:64': jasher8864,
  '1 Esdras 8:32': esdras832,
  '1 Esdras 8:36': esdras836,
  '1 Enoch 1:9': enoch1,
  '1 Enoch 13:1–11': enoch13,
  '1 Enoch 20:1–4': enoch20,
};

const jashurSource = 'Footnote refers to Sefer haYashar. Text below taken from '
    'The Book of Jasher, J.H. Parry & Company (1887):';
const jasher7927 = '$jashurSource\n\n'
    'And when they had gone Pharaoh sent for Balaam the magician '
    'and to Jannes and Jambres his sons, and to all the magicians and conjurors '
    'and counsellors which belonged to the king, and they all came and sat before the king.';
const jasher8863 = '$jashurSource\n\n'
    'And when they were smiting, the day was declining toward evening, '
    'and Joshua said in the sight of all the people, Sun, stand thou still upon '
    'Gibeon, and thou moon in the valley of Ajalon, until the nation shall have '
    'revenged itself upon its enemies.';
const jasher8864 = '$jashurSource\n\n'
    'And the Lord hearkened to the voice of Joshua, and the sun stood '
    'still in the midst of the heavens, and it stood still six and thirty '
    'moments, and the moon also stood still and hastened not to go down a whole day.';

// From public domain WEB version (https://ebible.org/engwebu/1ES08.htm):
const esdrasSource = 'Text below taken from World English Bible (WEB):';
const esdras832 = '$esdrasSource\n\n'
    'of the sons of Zathoes, Sechenias the son of Jezelus, '
    'and with him three hundred men; of the sons of Adin, Obeth the son of Jonathan, '
    'and with him two hundred fifty men;';
const esdras836 = '$esdrasSource\n\n'
    'of the sons of Banias, Salimoth son of Josaphias, and with '
    'him one hundred sixty men;';

// https://sacred-texts.com/bib/boe/index.htm
const enochSource = 'Text below taken from R.H. Charles translation (1917):';
const enoch1 = '$enochSource\n\n'
    'And behold! He cometh with ten thousands of ⌈His⌉ holy ones '
    'To execute judgement upon all, '
    'And to destroy ⌈all⌉ the ungodly: '
    'And to convict all flesh '
    'Of all the works ⌈of their ungodliness⌉ which they have ungodly committed, '
    'And of all the hard things which ungodly sinners ⌈have spoken⌉ against Him.';
const enoch13 = "$enochSource\n\n"
    "And Enoch went and said: 'Azâzêl, thou shalt have no peace: a severe sentence "
    "has gone forth against thee to put thee in bonds: And thou shalt not have "
    "toleration nor request granted to thee, because of the unrighteousness which "
    "thou hast taught, and because of all the works of godlessness and unrighteousness "
    "and sin which thou hast shown to men.' Then I went and spoke to them all together, "
    "and they were all afraid, and fear and trembling seized them. And they besought "
    "me to draw up a petition for them that they might find forgiveness, and to read "
    "their petition in the presence of the Lord of heaven. For from thenceforward "
    "they could not speak (with Him) nor lift up their eyes to heaven for shame of "
    "their sins for which they had been condemned. Then I wrote out their petition, "
    "and the prayer in regard to their spirits and their deeds individually and in "
    "regard to their requests that they should have forgiveness and length 〈of days. "
    "And I went off and sat down at the waters of Dan, in the land of Dan, to the "
    "south of the west of Hermon: I read their petition till I fell asleep. And "
    "behold a dream came to me, and visions fell down upon me, and I saw visions of "
    "chastisement, ⌈and a voice came bidding (me)⌉ I to tell it to the sons of heaven, "
    "and reprimand them. And when I awaked, I came unto them, and they were all sitting "
    "gathered together, weeping in ’Abelsjâîl, which is between Lebanon and Sênêsêr, "
    "with their faces covered. And I recounted before them all the visions which I had "
    "seen in sleep, and I began to speak the words of righteousness, and to reprimand "
    "the heavenly Watchers.";
const enoch20 = "$enochSource\n\n"
    "And these are the names of the holy angels who watch. "
    "Uriel, one of the holy angels, who is over the world and over Tartarus. "
    "Raphael, one of the holy angels, who is over the spirits of men. "
    "Raguel, one of the holy angels who takes vengeance on the world of the luminaries.";
