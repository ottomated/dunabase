import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:googleapis_auth/auth_io.dart';
import "package:http/http.dart" as http;
import "package:xml/xml.dart" as xml;
import 'dart:convert';
import 'dart:isolate';
import 'dart:async';
import 'dart:core';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'modal_progress_hud.dart';
import 'cross_off_text.dart';
import 'dual_panel.dart';
import 'package:encrypt/encrypt.dart';
import 'package:screen/screen.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() => runApp(new DunavaApp());

ServiceAccountCredentials credentials;

final String databaseVersion = '2.1';
final String spreadsheetUrl =
    'https://docs.google.com/spreadsheets/d/13WlZBIQodwZuu4olBTR3UlQJfw06JZ3KWuwQ9Ig9qBE/';

class VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => RotatedBox(
        quarterTurns: 1,
        child: Divider(),
      );
}

class DunavaCell {
  int row;
  int col;
  String value;
  DunavaCell(String row, String col, var value) {
    this.row = int.parse(row);
    this.col = int.parse(col);
    this.value = value == null ? "" : value.toString();
  }
  String toString() => "DunavaCell(${this.row},${this.col},\"${this.value}\")";
}

class DunavaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new DynamicTheme(
        defaultBrightness: Brightness.light,
        data: (brightness) => new ThemeData(
              primaryColor: Colors.red[800],
              accentColor: Colors.green[600],
              primaryColorDark: Colors.red[800],
              brightness: brightness,
            ),
        themedWidgetBuilder: (context, theme) {
          return new MaterialApp(
              title: 'Dunabase', home: new DunavaDatabase(), theme: theme);
        });
  }
}

class HelpPage extends StatefulWidget {
  @override
  createState() => new HelpPageState();
}

class HelpPageState extends State<HelpPage>
    with SingleTickerProviderStateMixin {
  int imageIndex = 0;
  int maxImage = 7;
  bool imagesCached = false;
  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = new TabController(vsync: this, length: maxImage + 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!imagesCached) {
      imagesCached = true;
      for (var j = 0; j < maxImage; j++) {
        var i = new AssetImage('assets/help/help$j.png',
            bundle: DefaultAssetBundle.of(context), package: null);
        precacheImage(i, context);
      }
    }
    var tbv = new TabBarView(
        controller: _tabController,
        children: [0, 1, 2, 3, 4, 5, 6, 7]
            .map((i) => new Image.asset('assets/help/help$i.png'))
            .toList());

    _tabController.addListener(() {
      setState(() {
        imageIndex = _tabController.index;
      });
    });

    var scaf = new Scaffold(
        appBar: new AppBar(
          backgroundColor: Color.fromRGBO(0, 66, 53, 1.0),
          title: new Text('help (${imageIndex + 1} of ${maxImage + 1})'),
        ),
        body: new Builder(builder: (BuildContext context) {
          return new Container(
              color: Color.fromRGBO(0, 40, 32, 1.0),
              child: new Center(child: tbv));
        }));
    return scaf;
  }
}

class DunavaDatabase extends StatefulWidget {
  @override
  createState() => new DunavaDatabaseState();
}

class DunavaDatabaseState extends State<DunavaDatabase>
    with SingleTickerProviderStateMixin {
  Map database = {};
  Map people = {
    "Christi": "XP",
    "Dina": "DT",
    "Fiore": "FG",
    "Hila": "HL",
    "Jen": "JM",
    "Jenny": "JS",
    "Meredith": "MS",
    "Olivia": "OG",
    "Raia": "RK",
    "Ramona": "RW",
    "Steph": "SB",
    "Tedy": "TD"
  };
  List<String> selectedPeople = [];
  bool _loading = false;
  String _loadingProgress = "";
  AnimationController spinRefresh;
  bool currentOnly = false;
  bool excludeW = false;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('dunabase'),
        actions: <Widget>[
          new AnimatedBuilder(
            child:
                IconButton(icon: Icon(Icons.refresh), onPressed: _refreshData),
            animation: spinRefresh,
            builder: (BuildContext context, Widget _widget) {
              double angle = spinRefresh.value * 6.3;
              if (!_loading) angle = 0.0;
              return new Transform.rotate(
                angle: angle,
                child: _widget,
              );
            },
          ),
          IconButton(
              icon: Icon(Icons.help_outline),
              onPressed: () {
                Navigator.of(context).push(new MaterialPageRoute(
                    builder: (BuildContext context) => new HelpPage()));

                Fluttertoast.showToast(
                    msg: "Swipe to navigate",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIos: 2,
                    bgcolor: "#0d0d0d",
                    textcolor: '#ffffff');
              }),
          IconButton(icon: Icon(Icons.settings), onPressed: _pushSettings),
        ],
      ),
      body: new ModalProgressHUD(
          child: _buildBody(),
          inAsyncCall: _loading,
          progressText: new IntrinsicHeight(
              child: new Container(
                  padding: const EdgeInsets.all(5.0),
                  child: new Center(child: Text("$_loadingProgress")),
                  decoration: new BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white),
                  width: MediaQuery.of(context).size.width)),
          progressIndicator: new LinearProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Go',
        child: Icon(Icons.arrow_forward),
        onPressed: _calculateCombos,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _getSharedPrefs();
    spinRefresh = new AnimationController(
      vsync: this,
      duration: new Duration(seconds: 1),
    );

    spinRefresh.repeat();
  }

  void _getSharedPrefs() {
    SharedPreferences.getInstance().then((prefs) {
      if (!prefs.getKeys().contains("excludeW"))
        prefs.setBool('excludeW', false);
      if (!prefs.getKeys().contains("currentOnly"))
        prefs.setBool('currentOnly', false);

      excludeW = prefs.getBool("excludeW");
      currentOnly = prefs.getBool("currentOnly");
      var json = new JsonDecoder();
      if (!prefs.getKeys().containsAll(["people", "data"])) {
        _refreshData();
      } else {
        database = json.convert(prefs.getString("data"));
        if (database["schemaVersion"] != databaseVersion) return _refreshData();
        people = json.convert(prefs.getString("people"));
      }
    });
  }

  List _doCalculations() {
    if (database.isEmpty) return [];
    var results = [];
    doSongW(song) {
      //print("\n\nDoing ${song["name"]}");
      var arrays = song["singers"].map((s) {
        var p = [s["parts"], s["wParts"]].expand((i) => i).toList();
        if (!selectedPeople.map((p) => people[p]).contains(s["name"]) ||
            p.length == 0) {
          return [null];
        } else {
          return p;
        }
      }).toList();
      //print(arrays);
      var perms = cartesianProduct(arrays);
      //print("Initial $perms");
      perms = perms.where((perm) {
        var canSing = true;
        if (song["parts"].length == 0) canSing = false;
        for (var part in song["parts"]) {
          //print('$part: ${perm.contains(part)}');
          if (!perm.contains(part)) {
            canSing = false;
            break;
          }
        }
        //print(canSing);
        return canSing;
      });
      //print("Final $perms");
      return perms.toList();
    }

    doSong(song) {
      //print("\n\nDoing ${song["name"]}");
      var arrays = song["singers"].map((s) {
        if (s["parts"].length == 0 ||
            !selectedPeople.map((p) => people[p]).contains(s["name"])) {
          return [null];
        } else {
          return s["parts"];
        }
      }).toList();
      var perms = cartesianProduct(arrays);
      //print("Initial $perms");
      perms = perms.where((perm) {
        var canSing = true;
        if (song["parts"].length == 0) canSing = false;
        for (var part in song["parts"]) {
          //print('$part: ${perm.contains(part)}');
          if (!perm.contains(part)) {
            canSing = false;
            break;
          }
        }
        //print(canSing);
        return canSing;
      });
      //print("Final $perms");
      return perms.toList();
    }

    database["songs"]
        .where((song) => !currentOnly || song["current"])
        .forEach((song) {
      if (!song["multi"]) {
        var perms = doSong(song);
        if (perms.length > 0) {
          results.add({
            "name": song["name"],
            "details": "",
            "song": song,
            "perms": perms,
            "w": false
          });
        } else if (!excludeW) {
          perms = doSongW(song);
          if (perms.length > 0) {
            results.add({
              "name": song["name"],
              "details": "W",
              "song": song,
              "perms": perms,
              "w": true
            });
          }
        }
      } else {
        bool canSing = true;
        bool w = false;
        var permsMap = {};
        for (var i in song["sections"].keys) {
          var perms = doSong(song["sections"][i]);
          if (perms.length == 0) {
            if (!excludeW) {
              perms = doSongW(song["sections"][i]);
              if (perms.length == 0) {
                canSing = false;
                break;
              } else {
                w = true;
              }
            } else {
              canSing = false;
              break;
            }
          }
          permsMap[i] = perms;
        }
        if (canSing) {
          results.add({
            "name": "${song["name"]}",
            "details": "${w ? "W — " : ""}${song["sections"].length} sections",
            "song": song,
            "perms": permsMap,
            "w": w
          });
        }
      }
    });
    return results;
  }

  void _calculateCombos() {
    var results = _doCalculations();

    results.sort((a, b) {
      if (a["w"]) return 1;
      if (b["w"]) return -1;
      return 0;
    });
    var notW = true;
    final List<List<Widget>> tiles = results.map(
      (song) {
        List<Widget> r = [];

        if (song["w"] && notW) {
          notW = false;
          r.add(new Divider());
        }

        if (song["details"] == "")
          r.add(new ListTile(
              title: new Text(song["name"]),
              trailing: new Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showSongDetails(song);
              }));
        else
          r.add(new ListTile(
              title: new Text(song["name"]),
              subtitle: new Text(song["details"]),
              trailing: new Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showSongDetails(song);
              }));
        return r;
      },
    ).toList();
    final List<Widget> divided = tiles.expand((i) => i).toList();

    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
          return new Scaffold(
            appBar: new AppBar(
              title: new Text('songs for this combo'),
            ),
            body: new Scrollbar(child: ListView(children: divided)),
          );
        },
      ),
    );
  }

  void _showSongDetails(song) {
    _fixColumns(List<Widget> columns) {
      var m = 0;
      columns
          .map((c) => (c as Column).children.length)
          .forEach((l) => m = l > m ? l : m);
      columns = columns.map((c) {
        var l = (c as Column).children.length;
        if (l < m) {
          (c as Column).children.addAll(new List.filled(
              m - l,
              new Container(
                  padding: const EdgeInsets.all(5.0), child: new Text(''))));
        }
        return (c as Column);
      }).toList();
      return columns;
    }

    parsePerm(perm, song) {
      //print(perm);
      int i = -1;
      perm = perm.map((part) {
        i++;
        String name = people.values.elementAt(i);
        var s = song["singers"].firstWhere((s) => s["name"] == name);
        return {"name": name, "part": part, "w": !s["parts"].contains(part)};
      });
      perm = perm.where((part) => part["part"] != null);
      return perm;
    }

    if (song["song"]["multi"]) {
      var perms = song["perms"];
      song = song["song"];
      Navigator.of(context).push(
        new MaterialPageRoute(
          builder: (context) {
            var sections = <Map<String, Widget>>[];
            for (var sec in song["sections"].keys) {
              var section = song["sections"][sec];
              //print(section);
              List<Widget> columns = [];
              List<Widget> rightColumns = [];
              for (var part in section["parts"]) {
                var header = new Container(
                    child: new Text(part,
                        style: new TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16.0)),
                    padding: const EdgeInsets.all(5.0));
                List<Widget> children = <Widget>[header];
                List<Widget> rightChildren = <Widget>[header];
                List news = parsePerm(perms[sec][0], section)
                    .where((p) => p["part"] == part)
                    .map((p) => {"text": p["name"], "w": p["w"]})
                    .toList();
                List rightNews = section["singers"]
                    .where((s) =>
                        selectedPeople
                            .map((p) => people[p])
                            .contains(s["name"]) &&
                        (s["parts"].contains(part) ||
                            s["wParts"].contains(part)))
                    .map((p) =>
                        {"text": p["name"], "w": !p["parts"].contains(part)})
                    .toList();
                children.addAll(news.map((a) => new CrossOffText(
                    text: a["text"],
                    highlight: a["w"],
                    padding: const EdgeInsets.all(5.0))));
                rightChildren.addAll(rightNews.map((a) => new CrossOffText(
                    text: a["text"],
                    highlight: a["w"],
                    padding: const EdgeInsets.all(5.0))));
                //print(children);
                //children.addAll(news);
                columns.add(new Column(children: children));
                rightColumns.add(new Column(children: rightChildren));
              }
              columns = _fixColumns(columns);
              rightColumns = _fixColumns(rightColumns);
              var header = new Container(
                  padding: const EdgeInsets.all(8.0),
                  child: new RichText(
                      textAlign: TextAlign.center,
                      text: new TextSpan(
                          text: '${sec.length < 2 ? "Section" : ""} $sec',
                          style: new TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 24.0),
                          children: [
                            new TextSpan(
                                text:
                                    '${section["details"] == "" ? "" : "\r\n"}${section["details"]}',
                                style: new TextStyle(fontSize: 20.0))
                          ])));
              sections.add({
                "left": new Column(children: <Widget>[
                  header,
                  new Row(
                    children: columns,
                    mainAxisAlignment: MainAxisAlignment.center,
                  )
                ]),
                "right": new Column(children: <Widget>[
                  header,
                  new Row(
                    children: rightColumns,
                    mainAxisAlignment: MainAxisAlignment.center,
                  )
                ])
              });
            }
            return new Scaffold(
              appBar: new AppBar(
                title: new Text('${song["name"]}'),
              ),
              body: new Scrollbar(
                  child: new ListView(
                      children: sections
                          .map((s) => [
                                new DualPanel(
                                    left: s["left"], right: s["right"]),
                                new Divider(color: Colors.grey)
                              ])
                          .expand((i) => i)
                          .toList())),
            );
          },
        ),
      );
    } else {
      var perms = song["perms"];

      song = song["song"];
      Navigator.of(context).push(
        new MaterialPageRoute(
          builder: (context) {
            List<Widget> columns = [];
            List<Widget> rightColumns = [];
            for (var part in song["parts"]) {
              var header = new Container(
                  child: new Text(part,
                      style: new TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16.0)),
                  padding: const EdgeInsets.all(5.0));
              List<Widget> children = <Widget>[header];
              List<Widget> rightChildren = <Widget>[header];
              List news = parsePerm(perms[0], song)
                  .where((p) => p["part"] == part)
                  .map((p) => {"text": p["name"], "w": p["w"]})
                  .toList();

              List rightNews = song["singers"]
                  .where((s) =>
                      selectedPeople
                          .map((p) => people[p])
                          .contains(s["name"]) &&
                      (s["parts"].contains(part) || s["wParts"].contains(part)))
                  .map((p) =>
                      {"text": p["name"], "w": !p["parts"].contains(part)})
                  .toList();
              children.addAll(news.map((a) => new CrossOffText(
                  text: a["text"],
                  highlight: a["w"],
                  padding: const EdgeInsets.all(5.0))));
              rightChildren.addAll(rightNews.map((a) => new CrossOffText(
                  text: a["text"],
                  highlight: a["w"],
                  padding: const EdgeInsets.all(5.0))));
              //print(children);
              //children.addAll(news);
              columns.add(new Column(children: children));
              rightColumns.add(new Column(children: rightChildren));
            }
            columns = _fixColumns(columns);
            rightColumns = _fixColumns(rightColumns);
            var header = new Container(
                padding: const EdgeInsets.all(8.0),
                child: new RichText(
                    textAlign: TextAlign.center,
                    text: new TextSpan(
                        text: '${song["details"]}',
                        style: new TextStyle(fontSize: 20.0))));
            Map<String, Widget> section = {
              "left": new Column(children: <Widget>[
                header,
                new Row(
                  children: columns,
                  mainAxisAlignment: MainAxisAlignment.center,
                )
              ]),
              "right": new Column(children: <Widget>[
                header,
                new Row(
                  children: rightColumns,
                  mainAxisAlignment: MainAxisAlignment.center,
                )
              ])
            };
            return new Scaffold(
                appBar: new AppBar(
                  title: new Text('${song["name"]}'),
                ),
                body: new ListView(children: [
                  new DualPanel(left: section["left"], right: section["right"])
                ]));
          },
        ),
      );
    }
  }

  _launchURL() async {
    if (await canLaunch(spreadsheetUrl)) {
      await launch(spreadsheetUrl);
    } else {
      throw 'Could not launch $spreadsheetUrl';
    }
  }

  void _pushSettings() {
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
          final tiles = [
            new SwitchListTile(
                value: Theme.of(context).brightness == Brightness.dark,
                title: new Text(
                    "${Theme.of(context).brightness == Brightness.dark ? "Dark" : "Light"} Mode"),
                activeColor: Theme.of(context).accentColor,
                onChanged: (bool value) {
                  setState(() {
                    DynamicTheme.of(context).setBrightness(
                        Theme.of(context).brightness == Brightness.dark
                            ? Brightness.light
                            : Brightness.dark);
                  });
                }),
            new SwitchListTile(
                title: new Text(
                    "${currentOnly ? "Current Repertoire Only" : "Full Repertoire"}"),
                activeColor: Theme.of(context).accentColor,
                value: currentOnly,
                onChanged: (bool value) {
                  setState(() {
                    currentOnly = value;
                    SharedPreferences.getInstance().then((prefs) {
                      prefs.setBool("currentOnly", currentOnly);
                    });
                    DynamicTheme
                        .of(context)
                        .setBrightness(Theme.of(context).brightness);
                  });
                }),
            new SwitchListTile(
                title: new Text(
                    "Tentative (w) Parts ${excludeW ? "Ex" : "In"}cluded"),
                value: excludeW,
                activeColor: Theme.of(context).accentColor,
                onChanged: (bool value) {
                  setState(() {
                    excludeW = value;
                    SharedPreferences.getInstance().then((prefs) {
                      prefs.setBool("excludeW", excludeW);
                    });
                    DynamicTheme
                        .of(context)
                        .setBrightness(Theme.of(context).brightness);
                  });
                }),
            new ListTile(
              title: new Text("View Spreadsheet"),
              trailing: Icon(Icons.open_in_new),
              onTap: _launchURL,
            ),
            new ListTile(
              title: new Text("App created by Otto Sapora, 15.7.18 through 17.8.18")
            )
          ];
          final divided = ListTile
              .divideTiles(
                context: context,
                tiles: tiles,
              )
              .toList();

          return new Scaffold(
            appBar: new AppBar(
              title: new Text('settings'),
            ),
            body: new ListView(children: divided),
          );
        },
      ),
    );
  }

  List<Widget> _buildTopListView() {
    List<Widget> ret = [];
    for (int i = 0; i < people.keys.length; i += 3) {
      ret.addAll([
        new Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildListItem(people.keys.elementAt(i)),
              new VerticalDivider(),
              _buildListItem(people.keys.elementAt(i + 1)),
              new VerticalDivider(),
              _buildListItem(people.keys.elementAt(i + 2)),
            ]),
        new Divider()
      ]);
    }
    return ret;
  }

  Widget _buildBody() {
    return new Column(children: <Widget>[
      new Expanded(
          child: new Scrollbar(
              child: new Container(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[820]
                      : Colors.white,
                  child: new ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: _buildTopListView())))),
      new Expanded(
          child: new Container(
              decoration: new BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[900]
                      : Colors.grey[200],
                  border: new Border(
                      top: new BorderSide(
                          color: Theme.of(context).dividerColor))),
              child: new ListView(
                physics: new BouncingScrollPhysics(),
                children: _generateDoubleColumnList(),
              )))
    ]);
  }

  Widget _buildListItem(String person) {
    Checkbox control = new Checkbox(
        value: selectedPeople.contains(person),
        activeColor: Theme.of(context).accentColor,
        onChanged: (bool value) {
          setState(() {
            if (selectedPeople.contains(person)) {
              selectedPeople.remove(person);
            } else {
              selectedPeople.add(person);
            }
          });
        });
    return new Container(
        width: 96.0,
        child: new Material(
            color: Color.fromRGBO(255, 255, 255, 0.0),
            child: new InkWell(
                onTap: () {
                  control.onChanged(!control.value);
                },
                child: new Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      new Text(person),
                      control,
                    ]))));
  }

  Widget _selectedListItem(String person) {
    return new Expanded(
        child: new Container(child: new Center(child: Text(person))));
  }

  List<Widget> _generateDoubleColumnList() {
    Container _buildItem(text) {
      return new Container(
          padding: EdgeInsets.all(5.0),
          child: new Center(
              child: new Text(
            text,
            style: new TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor),
          )));
    }

    List<Widget> result = [];
    result.add(_buildItem(
        "${selectedPeople.length} singer${selectedPeople.length == 1 ? "" : "s"} selected"));
    var results = _doCalculations();
    var ws = results.where((a) => a["w"]).length;
    var wtxt = "";
    if (ws > 0) {
      wtxt = '($ws tentative)';
    }

    result.add(_buildItem(
        "${results.length} song${results.length == 1 ? "" : "s"} for this combo $wtxt"));
    var when = "";
    if (database.isEmpty) {
      when = "never";
    } else {
      var d = DateTime.parse(database["lastUpdated"]).toLocal();
      var formatter = new DateFormat('MMM d hh:mm a');
      when = 'at ${formatter.format(d)}';
    }
    result.add(_buildItem("Database updated $when"));

    for (var i = 0; i < selectedPeople.length; i += 3) {
      String next = "";
      String next2 = "";

      if (i != selectedPeople.length - 1) {
        next = selectedPeople[i + 1];
      }

      if (i < selectedPeople.length - 2) {
        next2 = selectedPeople[i + 2];
      }

      result.add(new Row(children: <Widget>[
        _selectedListItem(selectedPeople[i]),
        _selectedListItem(next),
        _selectedListItem(next2)
      ]));
      result.add(new Divider());
    }
    return result;
  }

  void _refreshData() async {
    if (_loading) return;
    setState(() {
      _loading = true;
    });
    Screen.keepOn(true);
    void _doDecrypt(String _encryptionKey) async {
      String encryptionKey = _encryptionKey
          .substring(0, min(_encryptionKey.length, 32))
          .padRight(32);

      final encrypter = new Encrypter(new AES(encryptionKey));
      var text =
          '8d2bf9375d6fd7b9dbeeb89e1fb80fc7e367e4eb77e8ef718b8d6360612629ad1669de11fc96cc292cdb4ba979476f895226af08099fd10c885527d610101e1a5c7d7a96d02bc85570bb510b98ec18570512534334d4a386269e5fba65d03cdb4d3d2f5cab8416447fc5e861efcaebb66bdfc0d93b3a996d7d09d41c44486900f8efc2cc60de352042b1063cb66cf34942f26d81a990eb57ff655a2e8b636a796b107ce297e85416720d4881359c74f935b8c436fc797dd0275d566d15699e1a2556f18d1e4f8ec3d78e37a8b4fdf43f37dbcd4b3675758f5b2866616e43adec0c5350e95106328397692f10d199a3712262ec4daac3724c8e9c1e92bcb34c73aa44ca3a6d85f4624737c1ea8c939c75e692be4c5bc7676eb40e001827cb66564ac380f1bd71d9ba793441dbea672f7c35c2f063c60c2229bf8a702d88191cb9a5817dee214b877cd6c11cf2a2f79c7925cd206f1d3685241db5daf8933347139d84dce6a7045bd6ae3c5bdcbc7a8c336bb4ed4a0a5398ce9ac249a5c76c60cbc3dcbf1a8b100cead89a6f8dd964d61126db5eed911d3f994330f4c51e49ddb243991dbe5dc2191021a6c297311fdcb8da3693ed64c5eb243854fe851d00b1a5bdf7ab20d75ed5714e14e6b51b398dc4120c8f86cad45b409cced00498022697a0f5e97a62698ddc6057fa8be45f626ca82a5dcee70c0fcc3a437eeb4e7dfbe4642490e3c5824e903c80de47d2fa63ec65f9eb15def8495f8956857722682c9979c23d6dc845da61dfaa8c9a182f6d94bbb42a30ef535eff6a257ef92b8c2114d379214015b9449ef97c58d5f7a5d91a0eca51a4f834b22df2a0c3310ef3e3eae6fddd157669d8c3bb65324ed0a3b9f6f4a2b4780bdb636b6fc064e61272811fa7d3b21880e2c9d3bf5b1e3e9b704dd9c613d98462c96d54566e2e07713624d84a6ba161ee964984f86a8c0df427c6a5d561afe0434d0494f2b42c772ab9199f800c0d52b109944b2159796d2bf59f0693c686f36e2c8c7ab97d2b07ad1f9210bfc9cb50160583527e363ab5a069458d8c3d7de53e2569e32413dbe87c61e41badde91e972db234cbe1644d1f31c27b3c9356ce02621485b93dd5821ebe5770910afcc7e6af11b4530107bfc28d4f515ae5eb697b2b8cdbeecc0252c38a6bf98768a4ac4f7b34b8afe5d121df8fcdd24df308851a654c9ddee66533b18ee649cfada8db2cd63591cf8ad1e284912ad4240e1b48c23942d86f96ba9faf10fb5f06c7acf65c0741533ba19b6f3e5d65202dd5f7ae06484dc81b54b26eb0f5fb56c82085728aa4f7f9999173c287219d4160e9b313f13d34680a1d19c5e4f9a3b2a6f5f404e999fce0f18263df7ea00b60b6e679206f48be839d03fa1ff6827590ef098c5fc61cfa409626fed8031ed5f0c664f03b5824e007f4c3f475bea6caef55dc9b5ac35313cf2dff2be9159e19c6947adea8b2ed2213eb964fb69e88efeb67e947388ad8380f19bbd6c8a473eccd03221be208aa19eef1a4706211598d009de0d654014927d708146d243d6f65a21620d5ba49d446f637100675847367edef3c808ea39328fb650ef496f7f992bdbe9a5255ffb88cbcf315d7e90481b271934aea6222dff250f2b164f2dc6233f3e816a904a67178004416162b7578cf1769a0fa7d74d25af7cb96a01503887fa19d3f2c909f7f1c53bd8f342afc12f0aa163d4d15892c54d19af554a045d8960d01836d5d0145376417732a662b90a99e67368b7b4eec25654251862fb1acde6054266a45c4f5d13e1943e3fbe678ec15e91a58b69ad74ffa3ecd09965e27bf6717954c0ece456f15be2f4328351db76fea4fc645b10a30ad4b463f9cdc652e143ef2cebfb46367d729982e729a4d19e866776ad473098bbf6273b4eda3941acd3fccb0d97c9d9c78ea3e89884f2d24ee6efc955bccf9cad1e2685a59d63a5fe292ee6fc46e1e5dd2b975eb64cde8e8e61e5eb38905bbe98176bd8c716be37175a2834285b78521eb1fea449aed8e182f161a5938e0050f243a33d93f5fd98d38e99a14cb6841906b1d1bda7b66e47cab42ae24654bc37997beb27aa699a77403cc58830c945dbcad8a0c4095d946ad53ac4323c637456a46519e6cd3df4ca04f845483cda996a6dfcd5fb5e6cea213f24b6fc787a36ea9b3b3839ef34de992e706ccc7f5fe20848ba1a307b4d7fbb7d25ce21962b6123b49e4b563b37e3ca1bafc832034bd8fab77ce2aca6d6a26c2ffa82a52c9d6adb41c435d74303271fd3d04e732ae08bb0c1ccbf1b1dc4198118234729d76ca0efed58cf34aacac0fc50d71d01a3b7bcce423a2526510a84fff82c13300f49141bee17b1af34d29ad189864f5c967a488cd6600635fbf46a38f0b58280e01ef66597a1d7e95e2a6af30c303525ec6aa302c473c5b775a2803cf706abc98e9cbf3c5372fa2709998bdb0d49e68697988092f36b4e5b41cddd97e14b8e6de7b1a94257d083ac87e14710f77dd5cad59c59284b05373bc049f9229db7f998a041cfd3cf6591766bcbc5c8190af7a033a5b57da373951aff722c82206cf2a2ba5ce875e366b3919b06a2ea086c6ab4614ea577282d38fc858ac739b1fda8f632e93ec4d0e21dfdfab025a295bf7d3b064286fe81365b0cecb8e609d947e54fa988fb68a3cce5b0fa151c6f52562302b34ff1f03fae7eaa50c8d6767f67ef0e2bf4536b88f8c8a8fc6438d219842cb06a1675f0b6bd6e7d9ac2a0172e27a3269e848a68eeacae49a5a585a7b015c515611fc0fc03380d2190eea56642a2386428283a823d50aee301f0c31dbd27108916017b47e742f5d90823664c001b04c9de36c9ff317e300958cd8de7221807751d5dd2da34c8578be18cfbec77777a2e7b101b57d56c8876d63de673aac91e8dae34cd173dad0009209d0cae56cad1baba44106be3039c181c10ef63296bf289669cbf251af36fc2b81837b0e586964d43559711b9a587bdb2c202136300e7e4562bb168f8462970dd4f8b5826302277bfd1e12cfca9b022406f4938641b294f26efdf6d4bd37701ab0cc8df738100673b5e23735e087c9dd956f3d333c4c090d9e09ca3834e0e2916ef0bd685f2a8994df78037899907ddd6ff4bd9c9a4cd014d8fd4ad027053b9500eade9b3d5efd8d697d56abfcb51058262e130908fa507661463f2a0de0b77baacb268ebba6215ecbe4f65d8b4eb2e5be75b6bff6fb124e48504a65cb4aa475dc6ef7e3fa49147d131ac1aa54671ec42fe31cf22b5ed2ca2581dff231769a7c359cb70d40a';
      //print(text.length);
      //print(encrypter.encrypt(text));
      //Clipboard.setData(new ClipboardData(text: encrypter.encrypt(text)));
      var decryptedText = encrypter.decrypt(text);
      //print(decryptedText);
      //decryptedText = Uri.decodeComponent(decryptedText);
      if (!decryptedText.startsWith('{\n')) {
        showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) {
              return new AlertDialog(
                  title: new Text("Incorrect Code"),
                  content: new Text("Please try again"),
                  actions: <Widget>[
                    new FlatButton(
                      child: new Text("OKAY"),
                      onPressed: () {
                        Navigator.of(context).pop();
                        SharedPreferences.getInstance().then((prefs) {
                          prefs.setString('encryptionKey', '');
                        });

                        setState(() {
                          _loading = false;
                        });
                        _refreshData();
                      },
                    )
                  ]);
            });
      } else {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('encryptionKey', encryptionKey);
          credentials = new ServiceAccountCredentials.fromJson(decryptedText);
          _doRefreshData();
        });
      }
    }

    SharedPreferences.getInstance().then((prefs) {
      if (!prefs.getKeys().contains('encryptionKey'))
        prefs.setString('encryptionKey', '');
      var encryptionKey = prefs.getString('encryptionKey');

      if (encryptionKey.length == 0) {
        String _codeInput = '';
        showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) {
              return new AlertDialog(
                  title: new Text("Enter Code"),
                  content: new TextField(
                    autofocus: true,
                    onChanged: (String text) {
                      _codeInput = text;
                    },
                  ),
                  actions: <Widget>[
                    new FlatButton(
                      child: new Text("LOG IN"),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _doDecrypt(_codeInput);
                      },
                    )
                  ]);
            });
      } else {
        _doDecrypt(encryptionKey);
      }
    });
  }

  void _doRefreshData() async {
    /*showDialog(
      context: context, barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text('Rewind and remember'),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new Text('$_loadingProgress'),
                new Text('You\’re like me. I’m never satisfied.'),
              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text('Regret'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );*/
    var receivePort = new ReceivePort();
    await Isolate.spawn(_pullFromSpreadsheet, receivePort.sendPort);
    var f = true;
    await for (var msg in receivePort) {
      if (f) {
        var sP = msg as SendPort;
        if (database.isNotEmpty) {
          sP.send([credentials, database["lastUpdated"]]);
        } else {
          sP.send([credentials, ""]);
        }
        f = false;
        continue;
      }
      var data = msg as Map;
      if (data["type"] == "progress") {
        setState(() {
          _loadingProgress = data["data"];
        });
      } else if (data["type"] == "error") {
        receivePort.close();
        setState(() {
          _loadingProgress = "";
          _loading = false;
        });

        Screen.keepOn(false);
        showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) {
              return new AlertDialog(
                  title: new Text("Spreadsheet Error"),
                  content: new Text("${data["data"]}"),
                  actions: <Widget>[
                    new FlatButton(
                      child: new Text("OKAY"),
                      onPressed: () {
                        Navigator.of(context).pop();
                        SharedPreferences.getInstance().then((prefs) {
                          if (!prefs.getKeys().containsAll(["people", "data"]))
                            _refreshData();
                        });
                      },
                    )
                  ]);
            });
      } else if (data["type"] == "done") {
        receivePort.close();
        var l = data["data"];
        SharedPreferences.getInstance().then((prefs) {
          var json = new JsonEncoder();
          prefs.setString("data", json.convert(l[1]));
          prefs.setString("people", json.convert(l[0]));
        });
        setState(() {
          _loadingProgress = "";
          _loading = false;
          people = l[0];
          database = l[1];
        });
        Screen.keepOn(false);
      }
    }
    if (_loading) {
      setState(() {
        _loadingProgress = "";
        _loading = false;
      });
      Screen.keepOn(false);
      _refreshData();
    }

    // SharedPreferences.getInstance().then((prefs) {
    //   var json = new JsonEncoder();
    //   prefs.setString("data", json.convert(l[1]));
    //   prefs.setString("people", json.convert(l[0]));
    // });
    // setState(() {
    //   _loading = false;
    //   people = l[0];
    //   database = l[1];
    // });
    // compute(_pullFromSpreadsheet, _credentials).then((t) {
    //   print(t);
    // });
    // t.then((t) => t.then((l) {
    //   print(l);
    //       SharedPreferences.getInstance().then((prefs) {
    //         prefs.setString("data", l[1]);
    //       });
    //       setState(() {
    //         people = l[0];
    //       });
    //     }));
  }
}

_pullFromSpreadsheet(SendPort sendPort) async {
  var client = new http.Client();
  var rP = new ReceivePort();
  sendPort.send(rP.sendPort);
  List msg = await rP.first;
  var credentials = msg[0];
  String lastUpdated = msg[1];

  sendPort.send({"type": "progress", "data": "Authenticating"});
  var people = {};
  obtainAccessCredentialsViaServiceAccount(
          credentials, ["https://spreadsheets.google.com/feeds"], client)
      .then((AccessCredentials credentials) {
    String url =
        "https://spreadsheets.google.com/feeds/cells/13WlZBIQodwZuu4olBTR3UlQJfw06JZ3KWuwQ9Ig9qBE/od6/private/full?min-row=1&max-row=250&return-empty=true";

    sendPort.send({"type": "progress", "data": "Getting spreadsheet data"});

    client.get(url, headers: {
      "Authorization": "Bearer " + credentials.accessToken.data,
      "Gdata-Version": "3.0"
    }).then((response) {
      sendPort.send({"type": "progress", "data": "Parsing cells"});
      var parsed = xml.parse(response.body);
      String databaseUp =
          parsed.findAllElements("updated").first.firstChild.toString();
      if (lastUpdated == databaseUp) {
        throw "Database is already the latest version, no need to update";
      }
      dynamic cells = parsed.findAllElements("gs:cell");
      cells = cells
          .map((cell) => new DunavaCell(cell.getAttribute("row"),
              cell.getAttribute("col"), cell.firstChild))
          .toList();
      Map database = {
        "songs": [],
        "schemaVersion": databaseVersion,
        "lastUpdated": databaseUp
      };
      var singerNames = {};
      cells
          .where((c) =>
              c.row == 2 &&
              c.col > 4 &&
              (new RegExp("^[A-Z]{2}\$")).hasMatch(c.value))
          .forEach((c) {
        singerNames[c.col] = c.value;
        people[cells.firstWhere((c2) => c2.row == 1 && c2.col == c.col).value] =
            c.value;
      });

      cells
          .where((c) => c.col == 1 && c.row > 2 && c.value != "")
          .forEach((cell) {
        dynamic song = cell.value;

        sendPort.send({"type": "progress", "data": "$song: Starting"});
        var thisRow =
            cells.sublist(28 * (cell.row - 1), 28 * (cell.row - 1) + 28);
        String songName, songSection;
        bool multi = false;
        if (song.contains(' : ')) {
          multi = true;
          song = song.split(' : ');
          songName = song[0];
          songSection = song[1];
        }
        sendPort.send({"type": "progress", "data": "$song: Getting details"});
        var details = thisRow[2].value;
        sendPort
            .send({"type": "progress", "data": "$song: Getting current-ness"});
        var current = thisRow[3].value == "" ? false : true;
        sendPort.send({"type": "progress", "data": "$song: Getting parts"});
        var partsCell = thisRow[1];
        List<String> parts = partsCell.value.split(new RegExp(", *"));

        sendPort
            .send({"type": "progress", "data": "$song: Getting singer parts"});
        var singerParts = singerNames.map((col, _) {
          final value = thisRow[col - 1].value;
          if (value == "0" || value == "") {
            return new MapEntry(col, []);
          } else {
            return new MapEntry(col, value.split(new RegExp(", *")));
          }
        });
        sendPort.send(
            {"type": "progress", "data": "$song: Getting singer W parts"});
        var wSingerParts = singerNames.map((col, _) {
          final value = thisRow[col].value;
          if (value == "0" || value == "") {
            return new MapEntry(col, []);
          } else {
            return new MapEntry(col, value.split(new RegExp(", *")));
          }
        });

        var singers = [];

        singerNames.forEach((col, name) {
          singers.add({
            "name": name,
            "parts": singerParts[col],
            "wParts": wSingerParts[col]
          });
        });
        sendPort.send(
            {"type": "progress", "data": "$song: Adding song to database"});
        if (database["songs"].map((s) => s["name"]).contains(songName)) {
          var existingSong =
              database["songs"].firstWhere((s) => s["name"] == songName);
          if (!existingSong["multi"]) {
            throw "Error in spreadsheet: Check \"${existingSong["name"]}\". When a song has multiple rows, each section needs a colon and descriptor.";
          }
          existingSong["sections"][songSection] = {
            "parts": parts,
            "singers": singers,
            "details": details
          };
          existingSong["current"] = current || existingSong["current"];
        } else {
          if (!multi) {
            database["songs"].add({
              "name": song,
              "parts": parts,
              "multi": false,
              "singers": singers,
              "details": details,
              "current": current
            });
          } else {
            database["songs"].add({
              "name": songName,
              "multi": true,
              "current": current,
              "sections": {
                songSection: {
                  "parts": parts,
                  "singers": singers,
                  "details": details
                }
              }
            });
          }
        }
      });
      sendPort.send({"type": "progress", "data": "Complete"});
      client.close();
      sendPort.send({
        "type": "done",
        "data": [people, database]
      });
    }).catchError((err) {
      print(err);
      sendPort.send({"type": "error", "data": err.toString()});
    });
  }).catchError((err) {
    print(err);
    sendPort.send({"type": "error", "data": err.toString()});
  });
}

cartesianProduct(List args) {
  if (args.length == 0) throw "RangeError";
  var size = args.map((a) => a.length).reduce((a, b) => a * b);
  var result = [];
  for (int index = 0; index < size; index++) {
    result.add(nth(index, args));
  }
  return result;
}

nth(int n, List these) {
  var result = [];
  for (int d = 0; d < these.length; d++) {
    var l = these[d].length;
    var i = (n % l).floor();
    result.add(these[d][i]);
    n -= i;
    n = (n / l).floor();
  }
  return result;
}
