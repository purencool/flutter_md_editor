import 'package:flutter/material.dart';
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
  footnote,

  /// Adds a custom ID to a heading.
  headingId,

  /// Inserts a definition list.
  definitionList,

  /// Applies strikethrough style, using `~~text~~`.
  strikethrough,

  /// Inserts a task list item.
  taskList,

  /// Inserts an emoji.
  emoji,

  /// Applies highlight style, using `==text==`.
  highlight,

  /// Applies subscript style, using `~text~`.
  subscript,

  /// Applies superscript style, using `^text^`.
  superscript,
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

  bool isEditing = false;
  bool editable = false;

  @override
  void initState() {
    textController.text = widget.content;
    editable = widget.editable;
    super.initState();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
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
      case MarkdownStyle.footnote:
        prefix = "[^1]";
        suffix = "\n\n[^1]: This is the footnote.";
        break;
      case MarkdownStyle.headingId:
        suffix = " {#custom-id}";
        break;
      case MarkdownStyle.definitionList:
        prefix = "term\n: definition";
        break;
      case MarkdownStyle.strikethrough:
        prefix = "~~";
        suffix = "~~";
        break;
      case MarkdownStyle.taskList:
        prefix = "- [ ] ";
        break;
      case MarkdownStyle.emoji:
        prefix = ":joy:";
        break;
      case MarkdownStyle.highlight:
        prefix = "==";
        suffix = "==";
        break;
      case MarkdownStyle.subscript:
        prefix = "~";
        suffix = "~";
        break;
      case MarkdownStyle.superscript:
        prefix = "^";
        suffix = "^";
        break;
    }

    if (selected.isEmpty) {
      String newText = "$prefix$suffix";
      textController.text = "$textBefore$newText$textAfter";
      textController.selection = TextSelection.collapsed(
        offset: selection.start + prefix.length,
      );
    } else {
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
          newBefore = newBefore.substring(0, newBefore.length - prefix.length);
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
          extentOffset:
              textBefore.length + prefix.length + selected.length + suffix.length,
        );
      }
    }
    widget.onTextChanged?.call(textController.text);
  }

  /// Returns a `ButtonStyle` to ensure consistent styling for the toolbar icons.
  ButtonStyle buttonStyle() {
    return ButtonStyle(
      iconColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// Displays the markdown content when not in editing mode.
        if (!isEditing)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (editable) {
                  setState(() {
                    isEditing = true;
                  });
                }
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  textController.text.isEmpty
                      ? 'No content'
                      : textController.text,
                ),
              ),
            ),
          ),

        /// Displays the text field and the editing toolbar when in editing mode.
        if (isEditing)
          Expanded(
            child: Column(
              children: [
                /// Toolbar for markdown style buttons.
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
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
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Highlight',
                      onPressed: () => applyStyle(MarkdownStyle.highlight),
                      icon: PhosphorIcon(PhosphorIconsBold.highlighter),
                    ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Subscript',
                      onPressed: () => applyStyle(MarkdownStyle.subscript),
                      icon: PhosphorIcon(PhosphorIconsBold.textSubscript),
                    ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Superscript',
                      onPressed: () => applyStyle(MarkdownStyle.superscript),
                      icon: PhosphorIcon(PhosphorIconsBold.textSuperscript),
                    ),
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
                      onPressed: () => applyStyle(MarkdownStyle.link),
                      icon: PhosphorIcon(PhosphorIconsBold.link),
                    ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Image',
                      onPressed: () => applyStyle(MarkdownStyle.image),
                      icon: PhosphorIcon(PhosphorIconsBold.image),
                    ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Table',
                      onPressed: () => applyStyle(MarkdownStyle.table),
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
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Definition List',
                      onPressed: () => applyStyle(MarkdownStyle.definitionList),
                      icon: PhosphorIcon(PhosphorIconsBold.list),
                    ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Horizontal Rule',
                      onPressed: () => applyStyle(MarkdownStyle.horizontalRule),
                      icon: PhosphorIcon(PhosphorIconsBold.minus),
                    ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Footnote',
                      onPressed: () => applyStyle(MarkdownStyle.footnote),
                      icon: PhosphorIcon(PhosphorIconsBold.asterisk),
                    ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Heading ID',
                      onPressed: () => applyStyle(MarkdownStyle.headingId),
                      icon: PhosphorIcon(PhosphorIconsBold.tag),
                    ),
                    IconButton(
                      style: buttonStyle(),
                      tooltip: 'Emoji',
                      onPressed: () => applyStyle(MarkdownStyle.emoji),
                      icon: PhosphorIcon(PhosphorIconsBold.smiley),
                    ),
                  ]),
                ),
                Expanded(
                  child: TextField(
                    controller: textController,
                    expands: true,
                    minLines: null,
                    maxLines: null,
                    onChanged: widget.onTextChanged,
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
    );
  }
}
