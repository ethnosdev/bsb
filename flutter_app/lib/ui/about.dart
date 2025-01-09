import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:database_builder/schema.dart';
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
  late final List<(TextSpan, TextType, Format?)> paragraphs;
  late double paragraphSpacing;
  late double fontSize;
  late TextStyle _titleStyle;
  late TextStyle _contentStyle;

  final _versionNotifier = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _lookupVersionNumber();
    fontSize = getIt<UserSettings>().textSize;
    paragraphSpacing = fontSize * 0.6;
    _titleStyle = TextStyle(
      fontSize: fontSize * 1.2,
      fontWeight: FontWeight.bold,
    );
    _contentStyle = TextStyle(
      fontSize: fontSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final launchColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gratitude',
                style: _titleStyle,
              ),
              SizedBox(height: paragraphSpacing),
              Text(
                "I can't express how grateful I am to the producers of the Berean "
                "Standard Bible for releasing the BSB text to the public domain. "
                "This app would not exist otherwise. "
                "Here is their official statement: ",
                style: _contentStyle,
              ),
              SizedBox(height: paragraphSpacing),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Text.rich(
                  TextSpan(
                    style: _contentStyle,
                    children: [
                      const TextSpan(
                          text: "The Holy Bible, Berean Standard Bible, BSB is "
                              "produced in cooperation with "),
                      TextSpan(
                        text: "Bible Hub",
                        style: _contentStyle.copyWith(
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
                        style: _contentStyle.copyWith(
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
                        style: _contentStyle.copyWith(
                          color: launchColor,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            _launch('https://openbible.com/');
                          },
                      ),
                      const TextSpan(
                          text: ", and the Berean Bible Translation Committee. "
                              "This text of God's Word has been "),
                      TextSpan(
                        text: "dedicated to the public domain",
                        style: _contentStyle.copyWith(
                          color: launchColor,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            _launch('https://creativecommons.org/publicdomain/zero/1.0/');
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
                style: _contentStyle,
              ),
              SizedBox(height: paragraphSpacing),
              Text.rich(
                TextSpan(
                  style: _contentStyle,
                  children: [
                    const TextSpan(
                        text: "In the same spirit, EthosDev also dedicates this "
                            "app to the public domain. You can find "
                            "the source code on "),
                    TextSpan(
                      text: "GitHub",
                      style: _contentStyle.copyWith(
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
              Text(
                'Privacy',
                style: _titleStyle,
              ),
              SizedBox(height: paragraphSpacing),
              Text(
                "This app does not collect any personal information about you. ",
                style: _contentStyle,
              ),
              SizedBox(height: paragraphSpacing),
              Text(
                'Features',
                style: _titleStyle,
              ),
              SizedBox(height: paragraphSpacing),
              Text(
                "Many new features are being planned. "
                "These include selection and highlighting, full-text search, "
                "and looking up verses in the original Hebrew and Greek. ",
                style: _contentStyle,
              ),
              SizedBox(height: paragraphSpacing),
              Text(
                'Feedback',
                style: _titleStyle,
              ),
              SizedBox(height: paragraphSpacing),
              SelectableText(
                "If you have any other feature ideas or if you find a bug, "
                "please let me know by sending an email to contact@ethnos.dev.",
                style: _contentStyle,
              ),
              SizedBox(height: paragraphSpacing),
              Text(
                'App information',
                style: _titleStyle,
              ),
              SizedBox(height: paragraphSpacing),
              Text(
                "BSB version: 3rd printing",
                style: _contentStyle,
              ),
              ValueListenableBuilder<String>(
                valueListenable: _versionNotifier,
                builder: (context, version, child) {
                  return Text(
                    "App version: $version",
                    style: _contentStyle,
                  );
                },
              ),
              Text.rich(
                TextSpan(
                  style: _contentStyle,
                  children: [
                    const TextSpan(text: "Developer: "),
                    TextSpan(
                      text: "EthnosDev",
                      style: _contentStyle.copyWith(
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
      launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
