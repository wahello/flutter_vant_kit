import 'package:flutter/material.dart';
import 'package:flutter_vant_kit/theme/style.dart';
import 'package:image_picker/image_picker.dart';

//照片墙
class ImageWall extends StatefulWidget {
  // 图片文件数组
  final List<String>? images;

  // 是否可以多选图片
  final bool multiple;

  // 单行的图片数量
  final int length;

  // 最多可以选择的图片张数
  final int count;

  // 图片预览样式
  final BoxFit imageFit;

  // 自定义 button
  final Widget? uploadBtn;

  // 上传后返回全部图片信息
  final Function(List<String> newImages) onChange;

  // 监听图片上传
  final Future<List<String>> Function(List<XFile> file) onUpload;

  // 删除图片后的回调
  final Function(String? removedUrl)? onRemove;

  const ImageWall({
    Key? key,
    this.multiple = false,
    this.length = 4,
    this.count = 9,
    this.images,
    this.uploadBtn,
    this.imageFit = BoxFit.cover,
    required this.onChange,
    required this.onUpload,
    this.onRemove,
  }) : super(key: key);

  @override
  _ImageWall createState() => _ImageWall();
}

class _ImageWall extends State<ImageWall> {
  List<String> images = [];
  bool _uploading = false;
  double space = Style.imageWallItemGutter;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: Style.imageWallPadding,
        child: Wrap(
          direction: Axis.horizontal,
          spacing: space,
          runSpacing: space,
          children: buildImages(),
        ));
  }

  List<Widget> buildImages() {
    List<Widget> widgets = [];
    images = widget.images ?? [];
    for (int i = 0; i < images.length; i++) {
      widgets.add(_buildImageItem(i));
    }
    if (images.length < widget.count) {
      widgets.add(_buildAddImageButton());
    }
    return widgets;
  }

  Widget _buildImageItem(int index) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        ClipRRect(
            child: Image.network(
              images[index],
              fit: widget.imageFit,
              width: Style.imageWallItemSize,
              height: Style.imageWallItemSize,
            ),
            borderRadius:
                BorderRadius.circular(Style.imageWallItemBorderRadius)),
        Positioned(
          right: 0,
          top: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(Style.borderRadiusMax),
            child: Icon(Icons.cancel,
                color: Style.imageWallCloseButtonColor,
                size: Style.imageWallCloseButtonFontSize),
            onTap: () {
              String? removedUrl;
              setState(() {
                removedUrl = images.removeAt(index);
              });
              widget.onChange(images);
              if (widget.onRemove != null) {
                widget.onRemove!(removedUrl);
              }
            },
          ),
        )
      ],
    );
  }

  Widget _buildAddImageButton() {
    Widget btn = Container(
      width: Style.imageWallItemSize,
      height: Style.imageWallItemSize,
      decoration: BoxDecoration(
          border: Border.all(
            color: Style.imageWallUploadBorderColor,
          ),
          borderRadius: BorderRadius.circular(Style.imageWallItemBorderRadius)),
      child: Icon(Icons.add,
          color: Style.imageWallUploadColor, size: Style.imageWallUploadSize),
    );

    return InkWell(
      child: widget.uploadBtn ?? btn,
      onTap: _uploading ? null : _pickAndUpload,
    );
  }

  Future<void> _pickAndUpload() async {
    if (_uploading) return;
    setState(() => _uploading = true);
    try {
      final picker = ImagePicker();
      final source = picker.supportsImageSource(ImageSource.camera)
          ? await showModalBottomSheet<ImageSource>(
              context: context,
              builder: (context) {
                return SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.photo_library),
                        title: const Text('Gallery'),
                        onTap: () => Navigator.pop(context, ImageSource.gallery),
                      ),
                      ListTile(
                        leading: const Icon(Icons.camera_alt),
                        title: const Text('Camera'),
                        onTap: () => Navigator.pop(context, ImageSource.camera),
                      ),
                    ],
                  ),
                );
              },
            )
          : ImageSource.gallery;
      final remaining = widget.count - images.length;
      if (!mounted || source == null || remaining <= 0) return;

      final List<XFile> files;
      if (source == ImageSource.gallery && widget.multiple && remaining > 1) {
        files = await picker.pickMultiImage(limit: remaining);
      } else {
        final file = await picker.pickImage(source: source);
        files = file == null ? [] : [file];
      }
      if (!mounted || files.isEmpty) return;

      final urls = await widget.onUpload(files.take(remaining).toList());
      if (!mounted || urls.isEmpty) return;

      final available = widget.count - images.length;
      if (available <= 0) return;
      images.addAll(urls.take(available));
      widget.onChange(images);
    } on Exception catch (error) {
      debugPrint('ImageWall could not pick or upload images: $error');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}
