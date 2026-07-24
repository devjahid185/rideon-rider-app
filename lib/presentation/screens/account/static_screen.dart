import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart' as flutter_html;
import 'package:ride_on/core/utils/translate.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../cubits/static_page.dart';

class StaticScreen extends StatefulWidget {
  final String data;
  final bool? isBack;
  const StaticScreen({super.key, required this.data, this.isBack});
  @override
  State<StaticScreen> createState() => _StaticScreenState();
}

class _StaticScreenState extends State<StaticScreen> {
  String string = "";
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<StaticPageCubits>().getStaticData(context, data: widget.data);
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (widget.isBack == true) {
          goBack();
        } else {

        }

        return false;
      },
      child: Scaffold(
        backgroundColor: notifires.getbgcolor,
        appBar: widget.isBack == true
            ? CustomAppBars(
                title: widget.data,
                backgroundColor: notifires.getbgcolor,
                titleColor: notifires.getGrey1whiteColor)
            : AppBar(
                title: Text(
                  widget.data.translate(context),
                  style: heading2Grey1(context),
                ),
                centerTitle: true,
                automaticallyImplyLeading: false,
                backgroundColor: notifires.getbgcolor,
                scrolledUnderElevation: 0,
              ),
        body: BlocBuilder<StaticPageCubits, StaticPageState>(
            builder: (context, state) {
          if (state is StaticPageLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is StaticPageSuccess) {
            string = state.staticModel.data?.staticPage?.content ??
                "Content not available".translate(context);
          } else if (state is StaticPageFailure) {
            showErrorToastMessage(state.error);
          }
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: flutter_html.Html(
                  data: string, // Render HTML content
                  style: {
                    "body": flutter_html.Style(
                      color: notifires.getwhiteblackColor,
                      fontSize: flutter_html.FontSize(16.0),
                    ),
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}


