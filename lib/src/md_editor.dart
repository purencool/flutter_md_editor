import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// An enumeration of the markdown styles that can be applied.
enum MarkdownStyle {
  /// Applies bold style, using `**text**`.
  bold,

  /// Applies italic style, using `*text*`.
  italic,

  /// Applies heading 1 style, using `# text`.
  h1,

  /// Applies heading 2 style, using `## text`.
  h2,

  /// Applies heading 3 style, using `### text`.
  h3,

  /// Applies blockquote style, using `> text`.
  blockquote,

  /// Applies ordered list style, using `1. text`.
  orderedList,

  /// Applies unordered list style, using `- text`.
  unorderedList,

  /// Applies inline code style, using `` `text` ``.
  code,

  /// Inserts a horizontal rule, using `---`.
  horizontalRule,

  /// Inserts a link, using `title`.
  link,

  /// Inserts an image, using `!alt text`.
  image,

  /// Inserts a table template.
  table,

  /// Applies fenced code block style, using ``` ```.
  fencedCode,

  /// Inserts a footnote.
  //footnote,

  /// Adds a custom ID to a heading.
  //headingId,

  /// Inserts a definition list.
  //definitionList,

  /// Applies strikethrough style, using `~~text~~`.
  strikethrough,

  /// Inserts a task list item.
  taskList,

  /// Inserts an emoji.
  //emoji,

  /// Applies highlight style, using `==text==`.
  //highlight,

  /// Applies subscript style, using `~text~`.
  //subscript,

  /// Applies superscript style, using `^text^`.
  //superscript,
}

/// Defines an intent to select the current line of text.
class SelectLineIntent extends Intent {
  const SelectLineIntent();
}

/// A versatile markdown editor widget that allows for both viewing and editing
/// of markdown content.
///
/// This widget can be used as a simple markdown viewer when `editable` is
/// false, or as a full-featured markdown editor with a toolbar when `editable`
/// is true. The editor provides buttons to apply bold, italic, and title
/// styles to the text.
class MdEditor extends StatefulWidget {
  const MdEditor({
    super.key,
    required this.content,
    this.onTextChanged,
    this.editable = false,
  }) : assert(
         editable == false || onTextChanged != null,
         'If "editable" is true, "onTextChanged" is required.',
       );

  /// The initial markdown content to be displayed and edited.
  final String content;

  /// A boolean that determines whether the content can be edited.
  ///
  /// If `true`, a toolbar and a text field will be shown.
  /// If `false`, only the markdown content will be displayed.
  final bool editable;

  /// A callback function that is triggered when the text changes.
  ///
  /// This function receives the updated content string.
  ///
  /// Note: This parameter is required if `editable` is true, as enforced by the `assert`.
  final void Function(String content)? onTextChanged;

  /// Creates an `MdEditor` widget.
  ///
  /// The `content` is the initial markdown string.
  ///
  /// The `editable` flag controls the editing mode. If set to `true`, the
  /// `onTextChanged` callback must also be provided.

  @override
  State<MdEditor> createState() => _MdEditorState();
}

class _MdEditorState extends State<MdEditor> {
  final TextEditingController textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final Map<Type, Action<Intent>> _actions;

  bool isEditing = false;
  bool editable = false;

  @override
  void initState() {
    textController.text = widget.content;
    editable = widget.editable;
    _actions = <Type, Action<Intent>>{
      SelectLineIntent: CallbackAction<SelectLineIntent>(onInvoke: _selectLine),
    };
    super.initState();
  }

  @override
  void dispose() {
    textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String newText) {
    final selection = textController.selection;
    if (selection.baseOffset == -1) {
      widget.onTextChanged?.call(newText);
      return;
    }
    String textBefore = newText.substring(0, selection.baseOffset);
    String textAfter = newText.substring(selection.baseOffset);

    if (textBefore.endsWith('```') && selection.baseOffset >= 3) {
      String newContent = '$textBefore\n\n```$textAfter';
      textController.value = TextEditingValue(
        text: newContent,
        selection: TextSelection.collapsed(offset: selection.baseOffset + 1),
      );
      widget.onTextChanged?.call(textController.text);
      return;
    }

    if (textBefore.endsWith('`img ')) {
      String replacement = '![]()';
      String newBefore = textBefore.substring(0, textBefore.length - 4);
      String newContent = '$newBefore$replacement$textAfter';
      textController.value = TextEditingValue(
        text: newContent,
        selection: TextSelection.collapsed(
          offset: newBefore.length + replacement.length,
        ),
      );
      widget.onTextChanged?.call(textController.text);
      return;
    }

    if (textBefore.endsWith('`link ')) {
      String replacement = '[]()';
      String newBefore = textBefore.substring(0, textBefore.length - 5);
      String newContent = '$newBefore$replacement$textAfter';
      textController.value = TextEditingValue(
        text: newContent,
        selection: TextSelection.collapsed(
          offset: newBefore.length + replacement.length,
        ),
      );
      widget.onTextChanged?.call(textController.text);
      return;
    }

    final tableMatch = RegExp(r'\`t\[(\d+),(\d+)\]$').firstMatch(textBefore);
    if (tableMatch != null) {
      int rows = int.parse(tableMatch.group(1)!);
      int cols = int.parse(tableMatch.group(2)!);
      String tableMarkdown = _buildTable(rows, cols);
      String newBefore = textBefore.substring(0, tableMatch.start);
      String newContent = '$newBefore$tableMarkdown$textAfter';
      textController.value = TextEditingValue(
        text: newContent,
        selection: TextSelection.collapsed(
          offset: newBefore.length + tableMarkdown.length,
        ),
      );
      widget.onTextChanged?.call(textController.text);
      return;
    }

    widget.onTextChanged?.call(newText);
  }

  String _buildTable(int rows, int cols) {
    String tableMarkdown = '|';
    for (int i = 0; i < cols; i++) {
      tableMarkdown += ' Header |';
    }
    tableMarkdown += '\n|';
    for (int i = 0; i < cols; i++) {
      tableMarkdown += ' ----------- |';
    }
    tableMarkdown += '\n';
    for (int r = 0; r < rows; r++) {
      tableMarkdown += '|';
      for (int c = 0; c < cols; c++) {
        tableMarkdown += ' Cell |';
      }
      tableMarkdown += '\n';
    }
    return tableMarkdown;
  }

  /// Applies the specified markdown style to the selected text or at the current
  /// cursor position.
  ///
  /// If text is selected and the style is already applied, it will be removed.
  /// Otherwise, the style will be applied.
  /// If no text is selected, the style markers are inserted at the cursor position
  /// and the cursor is placed in the middle, ready for typing.
  ///
  /// @param style The `MarkdownStyle` to apply (e.g., `MarkdownStyle.bold`).
  void applyStyle(MarkdownStyle style) {
    var selection = textController.selection;
    String baseText = textController.text;

    if (selection.baseOffset == -1) {
      selection = TextSelection.collapsed(offset: baseText.length);
    }

    String textBefore = baseText.substring(0, selection.start);
    String selected = baseText.substring(selection.start, selection.end);
    String textAfter = baseText.substring(selection.end);

    // This is a list of styles that are applied to each line
    const lineStyles = [
      MarkdownStyle.h1,
      MarkdownStyle.h2,
      MarkdownStyle.h3,
      MarkdownStyle.blockquote,
      MarkdownStyle.orderedList,
      MarkdownStyle.unorderedList,
      MarkdownStyle.taskList,
    ];

    String prefix = "";
    String suffix = "";

    switch (style) {
      case MarkdownStyle.bold:
        prefix = "**";
        suffix = "**";
        break;
      case MarkdownStyle.italic:
        prefix = "*";
        suffix = "*";
        break;
      case MarkdownStyle.h1:
        prefix = "# ";
        break;
      case MarkdownStyle.h2:
        prefix = "## ";
        break;
      case MarkdownStyle.h3:
        prefix = "### ";
        break;
      case MarkdownStyle.blockquote:
        prefix = "> ";
        break;
      case MarkdownStyle.orderedList:
        prefix = "1. ";
        break;
      case MarkdownStyle.unorderedList:
        prefix = "- ";
        break;
      case MarkdownStyle.code:
        prefix = "`";
        suffix = "`";
        break;
      case MarkdownStyle.horizontalRule:
        prefix = "\n---\n";
        break;
      case MarkdownStyle.link:
        prefix = "";
        suffix = "";
        break;
      case MarkdownStyle.image:
        prefix = "!";
        suffix = "";
        break;
      case MarkdownStyle.table:
        prefix =
            "| Header | Title |\n| ----------- | ----------- |\n| Paragraph | Text |";
        break;
      case MarkdownStyle.fencedCode:
        prefix = "```\n";
        suffix = "\n```";
        break;
      // case MarkdownStyle.footnote:
      //  prefix = "[^1]";
      //  suffix = "\n\n[^1]: This is the footnote.";
      //  break;
      // case MarkdownStyle.headingId:
      //  suffix = " {#custom-id}";
      //  break;
      // case MarkdownStyle.definitionList:
      //  prefix = "term\n: definition";
      //  break;
      case MarkdownStyle.strikethrough:
        prefix = "~~";
        suffix = "~~";
        break;
      case MarkdownStyle.taskList:
        prefix = "- [ ] ";
        break;
    //  case MarkdownStyle.emoji:
    //    prefix = ":joy:";
    //    break;
    //  case MarkdownStyle.highlight:
    //    prefix = "==";
    //    suffix = "==";
    //    break;
    //  case MarkdownStyle.subscript:
    //    prefix = "~";
    //    suffix = "~";
    //    break;
    //  case MarkdownStyle.superscript:
    //    prefix = "^";
    //    suffix = "^";
    //    break;
    }

    if (selected.isEmpty) {
      String newText = "$prefix$suffix";
      textController.text = "$textBefore$newText$textAfter";
      textController.selection = TextSelection.collapsed(
        offset: selection.start + prefix.length,
      );
    } else {
      if (lineStyles.contains(style)) {
        // Handle line-by-line styles for multi-line selections
        final lines = selected.split('\n');
        // Check if all lines are already formatted
        bool allLinesFormatted;
        if (style == MarkdownStyle.orderedList) {
          allLinesFormatted =
              lines.every((line) => RegExp(r'^\d+\. ').hasMatch(line));
        } else {
          allLinesFormatted = lines.every((line) => line.startsWith(prefix));
        }

        if (allLinesFormatted) {
          // Un-apply the style from each line
          String newSelectedText;
          if (style == MarkdownStyle.orderedList) {
            newSelectedText = lines
                .map((line) => line.replaceFirst(RegExp(r'^\d+\. '), ''))
                .join('\n');
          } else {
            newSelectedText =
                lines.map((line) => line.substring(prefix.length)).join('\n');
          }
          textController.text = "$textBefore$newSelectedText$textAfter";
          textController.selection = TextSelection(
            baseOffset: textBefore.length,
            extentOffset: textBefore.length + newSelectedText.length,
          );
        } else {
          // Apply the style to each line
          String newSelectedText;
          if (style == MarkdownStyle.orderedList) {
            newSelectedText = lines.asMap().entries.map((entry) {
              int idx = entry.key;
              String line = entry.value;
              // Don't add number to empty lines
              return line.trim().isEmpty ? line : '${idx + 1}. $line';
            }).join('\n');
          } else {
            newSelectedText = lines.map((line) => '$prefix$line').join('\n');
          }
          textController.text = "$textBefore$newSelectedText$textAfter";
          textController.selection = TextSelection(
            baseOffset: textBefore.length,
            extentOffset: textBefore.length + newSelectedText.length,
          );
        }
      } else {
        // Handle wrapping styles
        bool formatted = false;
        if (prefix.isNotEmpty && suffix.isNotEmpty) {
          if (textBefore.endsWith(prefix) && textAfter.startsWith(suffix)) {
            formatted = true;
          }
        } else if (prefix.isNotEmpty) {
          if (textBefore.endsWith(prefix)) {
            formatted = true;
          }
        } else if (suffix.isNotEmpty) {
          if (textAfter.startsWith(suffix)) {
            formatted = true;
          }
        }

        if (formatted) {
          // Unapply the style
          String newBefore = textBefore;
          String newAfter = textAfter;

          if (prefix.isNotEmpty) {
            newBefore =
                newBefore.substring(0, newBefore.length - prefix.length);
          }
          if (suffix.isNotEmpty) {
            newAfter = newAfter.substring(suffix.length);
          }

          textController.text = "$newBefore$selected$newAfter";
          textController.selection = TextSelection(
            baseOffset: newBefore.length,
            extentOffset: newBefore.length + selected.length,
          );
        } else {
          // Apply the style
          textController.text = "$textBefore$prefix$selected$suffix$textAfter";
          textController.selection = TextSelection(
            baseOffset: textBefore.length,
            extentOffset: textBefore.length +
                prefix.length +
                selected.length +
                suffix.length,
          );
        }
      }
    }
    widget.onTextChanged?.call(textController.text);
  }

  Future<void> _onTapLink() async {
    var selection = textController.selection;
    final text = textController.text;

    if (selection.baseOffset == -1) {
      selection = TextSelection.collapsed(offset: text.length);
    }

    final selectedText = text.substring(selection.start, selection.end);
    String? inputUrl;
    String? inputText;

    await showDialog(
      context: context,
      builder: (context) {
        final urlController = TextEditingController();
        final textInputController = TextEditingController(text: selectedText);
        return AlertDialog(
          title: const Text('Insert Link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  hintText: 'https://example.com',
                ),
              ),
              TextField(
                controller: textInputController,
                decoration: const InputDecoration(
                  labelText: 'Text',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                inputUrl = urlController.text;
                inputText = textInputController.text;
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (inputUrl != null && inputText != null) {
      final newText = '[$inputText]($inputUrl)';
      final textBefore = text.substring(0, selection.start);
      final textAfter = text.substring(selection.end);

      textController.text = '$textBefore$newText$textAfter';
      textController.selection = TextSelection.collapsed(
        offset: selection.start + newText.length,
      );
      widget.onTextChanged?.call(textController.text);
    }
  }

  Future<void> _onTapImage() async {
    var selection = textController.selection;
    final text = textController.text;

    if (selection.baseOffset == -1) {
      selection = TextSelection.collapsed(offset: text.length);
    }

    final selectedText = text.substring(selection.start, selection.end);
    String? inputUrl;
    String? inputAlt;

    await showDialog(
      context: context,
      builder: (context) {
        final urlController = TextEditingController();
        final altController = TextEditingController(text: selectedText);
        return AlertDialog(
          title: const Text('Insert Image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  hintText: 'https://example.com/image.png',
                ),
              ),
              TextField(
                controller: altController,
                decoration: const InputDecoration(
                  labelText: 'Alt Text',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                inputUrl = urlController.text;
                inputAlt = altController.text;
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (inputUrl != null && inputAlt != null) {
      final newText = '![$inputAlt]($inputUrl)';
      final textBefore = text.substring(0, selection.start);
      final textAfter = text.substring(selection.end);

      textController.text = '$textBefore$newText$textAfter';
      textController.selection = TextSelection.collapsed(
        offset: selection.start + newText.length,
      );
      widget.onTextChanged?.call(textController.text);
    }
  }

  Future<void> _onTapTable() async {
    var selection = textController.selection;
    final text = textController.text;

    if (selection.baseOffset == -1) {
      selection = TextSelection.collapsed(offset: text.length);
    }

    int? inputRows;
    int? inputCols;

    await showDialog(
      context: context,
      builder: (context) {
        final rowsController = TextEditingController(text: '2');
        final colsController = TextEditingController(text: '2');
        return AlertDialog(
          title: const Text('Insert Table'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: rowsController,
                decoration: const InputDecoration(
                  labelText: 'Rows',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: colsController,
                decoration: const InputDecoration(
                  labelText: 'Columns',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                inputRows = int.tryParse(rowsController.text);
                inputCols = int.tryParse(colsController.text);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (inputRows != null && inputCols != null) {
      String tableMarkdown = _buildTable(inputRows!, inputCols!);

      final textBefore = text.substring(0, selection.start);
      final textAfter = text.substring(selection.end);

      textController.text = '$textBefore$tableMarkdown$textAfter';
      textController.selection = TextSelection.collapsed(
        offset: selection.start + tableMarkdown.length,
      );
      widget.onTextChanged?.call(textController.text);
    }
  }

  void _selectLine(SelectLineIntent intent) {
    final text = textController.text;
    final selection = textController.selection;

    if (selection.baseOffset == -1) {
      return;
    }

    final cursorPosition = selection.start;

    int lineStart = text.lastIndexOf('\n', cursorPosition - 1);
    lineStart = (lineStart == -1) ? 0 : lineStart + 1;

    int lineEnd = text.indexOf('\n', cursorPosition);
    if (lineEnd == -1) {
      lineEnd = text.length;
    }

    // If the line is already selected, subsequent presses could expand to include the newline,
    // but for now, this is a simple and predictable implementation.
    textController.selection = TextSelection(
      baseOffset: lineStart,
      extentOffset: lineEnd,
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Help & Usage'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Toolbar Actions:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('• Bold, Italic, Strikethrough, Code: Apply formatting to selected text.'),
                Text('• H1, H2, H3: Insert section headings.'),
                Text('• Blockquote: Format as a quote.'),
                Text('• Lists: Create numbered, bulleted, or task lists.'),
                Text('• Insert: Links, Images, Tables, Code Blocks, separators.'),
                SizedBox(height: 16),
                Text('Keyboard Shortcuts:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('• Select Text: Hold Shift and use the Arrow Keys.'),
                Text('• Select Line: Press Ctrl+L (or Cmd+L on macOS).'),
                SizedBox(height: 16),
                Text('Multi-line Formatting:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('After selecting multiple lines (e.g., with Shift+Arrows or Ctrl+L), you can apply line-based styles like headings or lists to all selected lines at once.'),
                SizedBox(height: 16),
                Text('Magic Shortcuts:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('• "```" : Insert Code Block'),
                Text('• "`img " : Insert Image'),
                Text('• "`link " : Insert Link'),
                Text('• "`t[rows,cols]" : Insert Table (e.g. `t[3,4])'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Returns a `ButtonStyle` to ensure consistent styling for the toolbar icons.
  ButtonStyle buttonStyle() {
    return ButtonStyle(
      iconColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyL):
            const SelectLineIntent(),
        // Add Cmd+L for macOS
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyL):
            const SelectLineIntent(),
      },
      child: Actions(
        actions: _actions,
        child: Column(
          children: [
          Expanded(
            child: Column(
              children: [
                /// Toolbar for markdown style buttons.
                Wrap(
                  children: [
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Save',
                      onPressed: () {
                        setState(() {
                          isEditing = false;
                        });
                        widget.onTextChanged!(textController.text);
                      },
                      icon: PhosphorIcon(PhosphorIconsBold.floppyDisk),
                    ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'H1',
                      onPressed: () => applyStyle(MarkdownStyle.h1),
                      icon: PhosphorIcon(PhosphorIconsBold.textHOne),
                    ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'H2',
                      onPressed: () => applyStyle(MarkdownStyle.h2),
                      icon: PhosphorIcon(PhosphorIconsBold.textHTwo),
                    ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'H3',
                      onPressed: () => applyStyle(MarkdownStyle.h3),
                      icon: PhosphorIcon(PhosphorIconsBold.textHThree),
                    ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Bold',
                      onPressed: () => applyStyle(MarkdownStyle.bold),
                      icon: PhosphorIcon(PhosphorIconsBold.textB),
                    ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Italic',
                      onPressed: () => applyStyle(MarkdownStyle.italic),
                      icon: PhosphorIcon(PhosphorIconsBold.textItalic),
                    ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Strikethrough',
                      onPressed: () => applyStyle(MarkdownStyle.strikethrough),
                      icon: PhosphorIcon(PhosphorIconsBold.textStrikethrough),
                    ),
                  //  IconButton(
                  //    style: buttonStyle(),
                  //    tooltip: 'Highlight',
                  //    onPressed: () => applyStyle(MarkdownStyle.highlight),
                  //    icon: PhosphorIcon(PhosphorIconsBold.highlighter),
                  //  ),
                  //  IconButton(
                  //    style: buttonStyle(),
                  //    tooltip: 'Subscript',
                  //    onPressed: () => applyStyle(MarkdownStyle.subscript),
                  //    icon: PhosphorIcon(PhosphorIconsBold.textSubscript),
                  //  ),
                  //  IconButton(
                  //    style: buttonStyle(),
                  //    tooltip: 'Superscript',
                  //    onPressed: () => applyStyle(MarkdownStyle.superscript),
                  //    icon: PhosphorIcon(PhosphorIconsBold.textSuperscript),
                  //  ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Blockquote',
                      onPressed: () => applyStyle(MarkdownStyle.blockquote),
                      icon: PhosphorIcon(PhosphorIconsBold.quotes),
                    ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Code',
                      onPressed: () => applyStyle(MarkdownStyle.code),
                      icon: PhosphorIcon(PhosphorIconsBold.code),
                    ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Fenced Code',
                      onPressed: () => applyStyle(MarkdownStyle.fencedCode),
                      icon: PhosphorIcon(PhosphorIconsBold.bracketsCurly),
                    ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Link',
                      onPressed: _onTapLink,
                      icon: PhosphorIcon(PhosphorIconsBold.link),
                    ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Image',
                      onPressed: _onTapImage,
                      icon: PhosphorIcon(PhosphorIconsBold.image),
                    ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Table',
                      onPressed: _onTapTable,
                      icon: PhosphorIcon(PhosphorIconsBold.table),
                    ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Ordered List',
                      onPressed: () => applyStyle(MarkdownStyle.orderedList),
                      icon: PhosphorIcon(PhosphorIconsBold.listNumbers),
                    ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Unordered List',
                      onPressed: () => applyStyle(MarkdownStyle.unorderedList),
                      icon: PhosphorIcon(PhosphorIconsBold.listBullets),
                    ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Task List',
                      onPressed: () => applyStyle(MarkdownStyle.taskList),
                      icon: PhosphorIcon(PhosphorIconsBold.checkSquare),
                    ),
                   // IconButton(
                   //   style: buttonStyle(),
                   //   tooltip: 'Definition List',
                   //   onPressed: () => applyStyle(MarkdownStyle.definitionList),
                   //   icon: PhosphorIcon(PhosphorIconsBold.list),
                   // ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Horizontal Rule',
                      onPressed: () => applyStyle(MarkdownStyle.horizontalRule),
                      icon: PhosphorIcon(PhosphorIconsBold.minus),
                    ),
                   // IconButton(
                   //   style: buttonStyle(),
                   //   tooltip: 'Footnote',
                   //   onPressed: () => applyStyle(MarkdownStyle.footnote),
                   //   icon: PhosphorIcon(PhosphorIconsBold.asterisk),
                   // ),
                   // IconButton(
                   //   style: buttonStyle(),
                   //   tooltip: 'Heading ID',
                   //   onPressed: () => applyStyle(MarkdownStyle.headingId),
                   //   icon: PhosphorIcon(PhosphorIconsBold.tag),
                   // ),
                   // IconButton(
                   //   style: buttonStyle(),
                   //   tooltip: 'Emoji',
                   //   onPressed: () => applyStyle(MarkdownStyle.emoji),
                   //   icon: PhosphorIcon(PhosphorIconsBold.smiley),
                   // ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Help',
                      onPressed: _showHelp,
                      icon: PhosphorIcon(PhosphorIconsBold.question),
                    ),
                  ],
                ),
                Expanded(
                  child: TextField(
                    focusNode: _focusNode,
                    controller: textController,
                    expands: true,
                    minLines: null,
                    maxLines: null,
                    onChanged: _onTextChanged,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Type here...",
                    ),
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}
