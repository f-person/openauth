import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/translations.dart';
import 'package:openauth/about/about.dart';
import 'package:openauth/database/notifier.dart';
import 'package:openauth/entry/entry.dart';
import 'package:openauth/entry/entry_input_page.dart';
import 'package:openauth/entry/entry_list.dart';
import 'package:openauth/scan/scan_route.dart';
import 'package:openauth/settings/notifier.dart';
import 'package:openauth/settings/provider.dart';
import 'package:openauth/settings/settings.dart';
import 'package:provider/provider.dart';

enum Action { input, scan }
enum Option { edit, remove }
enum Menu { settings, about }

extension OptionExtensions on Option {
  Widget get icon {
    switch (this) {
      case Option.edit:
        return const Icon(Icons.edit_outlined);
      case Option.remove:
        return const Icon(Icons.delete_outline);
    }
  }

  String getLocalization(context) {
    switch (this) {
      case Option.edit:
        return Translations.of(context)!.button_edit;
      case Option.remove:
        return Translations.of(context)!.button_remove;
    }
  }
}

class EntryPage extends StatefulWidget {
  const EntryPage({Key? key}) : super(key: key);

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  Future<Action?> _invokeMainActions() async {
    return await showModalBottomSheet(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Translations.of(context)!.title_add_account,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 18)),
                  const SizedBox(height: 32),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context, Action.scan);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(Icons.qr_code_scanner_outlined),
                                  const SizedBox(width: 16),
                                  Text(Translations.of(context)!.button_scan)
                                ],
                              ),
                            )),
                        OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context, Action.input);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_outlined),
                                  const SizedBox(width: 16),
                                  Text(Translations.of(context)!.button_input)
                                ],
                              ),
                            ))
                      ]),
                  const SizedBox(height: 16)
                ],
              ),
            ),
          );
        });
  }

  Future<Option?> _invokeOptions(context) async {
    return await showModalBottomSheet(
        context: context,
        builder: (context) {
          return ListView(
            shrinkWrap: true,
            children: Option.values.map((option) {
              return ListTile(
                leading: option.icon,
                title: Text(option.getLocalization(context)),
                onTap: () {
                  Navigator.pop(context, option);
                },
              );
            }).toList(),
          );
        });
  }

  Future<Sort?> _invokeSortMenu(
    PreferenceNotifier preferenceNotifier,
  ) async {
    return await showModalBottomSheet<Sort>(
        context: context,
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(Translations.of(context)!.menu_sort,
                    style: Theme.of(context).textTheme.headline6),
              ),
              ListView(
                shrinkWrap: true,
                children: Sort.values.map((sort) {
                  return ListTile(
                    leading: Icon(preferenceNotifier.preferences.sort == sort
                        ? Icons.check
                        : null),
                    title: Text(
                      sort.getLocalization(context),
                    ),
                    onTap: () {
                      preferenceNotifier.changeSort(sort);
                      Navigator.pop(context, sort);
                    },
                  );
                }).toList(),
              ),
            ],
          );
        });
  }

  Future<bool> _invokeRemoveDialog() async {
    return await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                title: Text(Translations.of(context)!.dialog_remove_entry),
                content: Text(
                    Translations.of(context)!.dialog_remove_entry_subtitle),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: Text(
                        Translations.of(context)!.button_cancel.toUpperCase()),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    child: Text(
                        Translations.of(context)!.button_remove.toUpperCase()),
                  ),
                ],
              );
            }) ??
        false;
  }

  Future _invokeEditor(EntryNotifier notifier) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return ChangeNotifierProvider<EntryNotifier>.value(
            value: notifier, child: const InputPage());
      }),
    );
    switch (result) {
      case Operation.create:
        _showSnackBar(Translations.of(context)!.feedback_entry_created);
        break;
      case Operation.update:
        _showSnackBar(Translations.of(context)!.feedback_entry_updated);
        break;
      default:
        break;
    }
    return true;
  }

  void _onTap(code) {
    Clipboard.setData(ClipboardData(text: code)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              Translations.of(context)!.feedback_code_copied_to_clipboard)));
    });
  }

  void _onLongPress(Entry entry) async {
    final result = await _invokeOptions(context);
    switch (result) {
      case Option.edit:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => InputPage(entry: entry)));
        break;
      case Option.remove:
        final response = await _invokeRemoveDialog();
        if (response) {
          await Provider.of<EntryNotifier>(context, listen: false)
              .remove(entry);
          _showSnackBar(Translations.of(context)!.feedback_entry_removed);
        }
        break;
      default:
        break;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EntryNotifier>(builder: (context, notifier, child) {
      return Consumer<PreferenceNotifier>(
          builder: (context, preferenceNotifier, child) {
        return Scaffold(
          body: CustomScrollView(slivers: [
            SliverAppBar(
              pinned: true,
              title: Text(
                Translations.of(context)!.app_name,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            EntryList(
              entries: notifier.entries,
              enableDragging:
                  preferenceNotifier.preferences.sort != Sort.custom,
              hideToken: preferenceNotifier.preferences.hideTokens,
              onTap: preferenceNotifier.preferences.tapToCopy ? _onTap : null,
              onLongTap: _onLongPress,
            ),
          ]),
          floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                if (Platform.isAndroid || Platform.isIOS) {
                  final Action? result = await _invokeMainActions();
                  if (result != null) {
                    switch (result) {
                      case Action.input:
                        await _invokeEditor(notifier);
                        break;
                      case Action.scan:
                        final Entry? data = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ChangeNotifierProvider<EntryNotifier>.value(
                                    value: notifier, child: const ScanRoute()),
                          ),
                        );
                        if (data != null && data is Entry) {
                          notifier.put(data);
                          _showSnackBar(
                              Translations.of(context)!.feedback_entry_created);
                        }
                        break;
                    }
                  }
                } else {
                  await _invokeEditor(notifier);
                }
              },
              icon: const Icon(Icons.add),
              label: Text(Translations.of(context)!.button_add)),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: BottomAppBar(
            child: Row(children: [
              const Spacer(),
              IconButton(
                  onPressed: () async {
                    final result = await _invokeSortMenu(preferenceNotifier);
                    if (result != null) {
                      notifier.sort(result);
                    }
                  },
                  icon: const Icon(Icons.sort)),
              PopupMenuButton<Menu>(
                onSelected: (route) => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    switch (route) {
                      case Menu.settings:
                        return const SettingsRoute();
                      case Menu.about:
                        return const AboutRoute();
                    }
                  }),
                ),
                itemBuilder: (context) => <PopupMenuEntry<Menu>>[
                  PopupMenuItem(
                      child: Text(Translations.of(context)!.menu_settings),
                      value: Menu.settings),
                  PopupMenuItem(
                      child: Text(Translations.of(context)!.menu_about),
                      value: Menu.about)
                ],
              )
            ]),
          ),
        );
      });
    });
  }
}
