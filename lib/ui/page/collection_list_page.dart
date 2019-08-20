import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fun_android/generated/i18n.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'package:fun_android/config/router_config.dart';
import 'package:fun_android/flutter/refresh_animatedlist.dart';
import 'package:fun_android/model/article.dart';
import 'package:fun_android/provider/provider_widget.dart';
import 'package:fun_android/ui/widget/article_list_Item.dart';
import 'package:fun_android/ui/widget/page_state_switch.dart';
import 'package:fun_android/view_model/colletion_model.dart';
import 'package:fun_android/view_model/login_model.dart';

class CollectionListPage extends StatelessWidget {
  final GlobalKey<SliverAnimatedListState> listKey =
      GlobalKey<SliverAnimatedListState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).myFavourites),
      ),
      body: ProviderWidget<CollectionListModel>(
        model:
            CollectionListModel(loginModel: LoginModel(Provider.of(context))),
        onModelReady: (model) async {
          await model.initData();
        },
        builder: (context, model, child) {
          if (model.busy) {
            return PageStateListSkeleton();
          }
          if (model.error) {
            return PageStateError(onPressed: model.initData);
          }
          if (model.empty) {
            return PageStateEmpty(onPressed: model.initData);
          }
          if (model.unAuthorized) {
            return PageStateUnAuthorized(onPressed: () async {
              var success =
                  await Navigator.of(context).pushNamed(RouteName.login);
              // 登录成功,获取数据,刷新页面
              if (success ?? false) {
                model.initData();
              }
            });
          }
          return SmartRefresher(
              controller: model.refreshController,
              header: WaterDropHeader(),
              onRefresh: () async {
                await model.refresh();
                listKey.currentState.refresh(model.list.length);
              },
              onLoading: () async {
                await model.loadMore();
                listKey.currentState.refresh(model.list.length);
              },
              enablePullUp: true,
              child: CustomScrollView(slivers: <Widget>[
                SliverAnimatedList(
                    key: listKey,
                    initialItemCount: model.list.length,
                    itemBuilder: (context, index, animation) {
                      Article item = model.list[index];
                      return Slidable(
                        actionPane: SlidableDrawerActionPane(),
                        secondaryActions: <Widget>[
                          IconSlideAction(
                            caption: '移除收藏',
                            color: Colors.redAccent,
                            icon: Icons.delete,
                            onTap: () {
                              CollectionModel(item).collect();
                              model.list.removeAt(index);
                              listKey.currentState.removeItem(
                                  index,
                                  (context, animation) => SizeTransition(
                                      axis: Axis.vertical,
                                      axisAlignment: 1.0,
                                      sizeFactor: animation,
                                      child: ArticleItemWidget(item)));
                            },
                          )
                        ],
                        child: SizeTransition(
                            axis: Axis.vertical,
                            sizeFactor: animation,
                            child: ArticleItemWidget(item)),
                      );
                    })
              ]));
        },
      ),
    );
  }
}
