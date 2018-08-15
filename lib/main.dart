import 'package:flutter/material.dart';

import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:googleapis_auth/auth_io.dart';
import "package:http/http.dart" as http;
import "package:xml/xml.dart" as xml;
import 'dart:convert';
import 'dart:isolate';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'modal_progress_hud.dart';
import 'cross_off_text.dart';
import 'dual_panel.dart';

void main() => runApp(new DunavaApp());

final String databaseVersion = '1.0';

final String spreadsheetUrl =
    'https://docs.google.com/spreadsheets/d/13WlZBIQodwZuu4olBTR3UlQJfw06JZ3KWuwQ9Ig9qBE/';

final ServiceAccountCredentials _credentials =
    new ServiceAccountCredentials.fromJson(r'''
{
  "type": "service_account",
  "project_id": "dunava-database",
  "private_key_id": "30a4b6b457445f5edf17b469e6c483e235f9b266",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDSO8ILt+wjtF1r\ne7yS9/XcdqcaAeZxE0IX15zsU3fSGXYRteYs+3ueNyUja1ya7BPs6UZli9dQqfHx\nP/wbxPGlOgkGYyLWt2SmtqQyjPprfVuP20WoOPBAXgudfuGjKh27ATDK3E6+G3l4\nd5PV+Vnl9uYqpKzF4J1rSATgKfc+aMsiGHsH94DEmQVf5EyB5G1wsljzvJ2ok222\nzwamYiDnZ5D/tB1ZHY8YYSLqoIZs0BkG2U3QU1uaq7XpN/cyX92z0bg0F7LdrA18\nmq24agv0U0esd0aNZUXgTHlhbrg75/AgOAJCaiyWTk+xUjzlT2ZeKbUmUAp6BFqj\nA/M2jUaFAgMBAAECggEAEAPDWAyDrYNGK946KDaWq7D827X8rZfE93dSRI0QhJhc\nmSQdIPIV9vXGcM3zOPig2pw5OO+6etznSZ8RKmBfSVyEEXt9zOjIKbb3XRkbfmgH\nOzcoiumuIN5zzg87Sv2gqX0sEAKmRkRmMBoT0JSfwi0uWAiWrLWGkwSNHTJf24i7\n6Y5D0AmdXr3grz9Wegoe+PcljtkSb1GuhQIK0ufD6SFrDUwuCJhCvua0cPAYG9dE\noyosNEryDqWwqyK4kirANdx1zoEH1CJwOWFzZsMPRAgaOdZ6sWDsbHN69hcOkEMH\nGJzUdqWFFBxofFgLswrJCIc/vAfNCC5XdAHNkRjEgQKBgQD+gBFAGIZs+9qCco4d\nJNSfB3HCSK1/x36cc0RA0VdpovWayJG38jeKncNV/It3Titb7+LwFoOcNVbt5NgJ\n8Dt7hRP5s22WIbq8MdEk8v1627q3L/NnouXAnFPoHWUgls4owZuu0M4J4OeGWrEN\nLpufXhEgIO5MhRfaEYMpe8tUYQKBgQDTeOkpfC374xsU6TL0ImtsacsMVfj76aft\nT+N1kRWlzcUBt2Mtn1L3lSfXlIFXDMMa8QsDMfd822eVmh9dbXTAgP3thuUICxYI\nIHcBAjeGsuz9cH8xvP/dMGvwt6K6ZT7eewF16avOhyysnjRWM8wYvVEYQ0yGzIgD\nzoLyS8pkpQKBgDUiofdi53YLo1SG/FrjXK0TTdIFgIvkJ/AcNMzfqEN67ZJye9IO\n9T+wrp7eSnQPUwgv7o639KSBknO6ysxQZurkHwaMSr4ErssqD4OKZBfplnM2xLgH\nj7aGLRKSSJHkSojB23JFUC9J0K0BdGPPLli4uBSgK4C4bQFvlJXtrcchAoGADc9/\nqq3pcuHKCvuP0FHPIi1mjU+wCwOfa+gjurHW8BUYIJyRZZFaIcEj8PhJ2h2DQGct\niO/icc0CXsrJ8ZgMX+YMr0539qaCsdUs8GvspGdbAtIt/FmTfCaFZhsYDYQ/Lthp\nqAGyrrI1QLC0Skznr1Xtzd/XR5Zj65u5AYnhleECgYAUxW5w8oj+P25b6wXNK5dJ\n4iDJnGEAPiCjsAkpG0bfVkAc94mosL84ruNubIYyyDoCA2GPm/L1BVH2WImi/GWl\nlvXrjlafbEM6S9IHY9CRn8VLJrfIXDMpRWiVeHmUaZhWjZYEDrpBXt4B8NXg2Qpi\nyyRvhe/Ye4h8Lr/8vbXffA==\n-----END PRIVATE KEY-----\n",
  "client_email": "dunava-database@dunava-database.iam.gserviceaccount.com",
  "client_id": "117021163158761479529",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://accounts.google.com/o/oauth2/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/dunava-database%40dunava-database.iam.gserviceaccount.com"
}
''');

class DunavaCell {
  int row;
  int col;
  String value;
  DunavaCell(String row, String col, var value) {
    this.row = int.parse(row);
    this.col = int.parse(col);
    this.value = value.toString();
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
          IconButton(icon: Icon(Icons.settings), onPressed: _pushSettings)
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
      print('$excludeW, $currentOnly');
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

  void _calculateCombos() {
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
              "details": "*",
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
            "details": "${w ? "* | " : ""}${song["sections"].length} sections",
            "song": song,
            "perms": permsMap,
            "w": w
          });
        }
      }
    });

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
            body: new ListView(children: divided),
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
                            s["parts"].contains(part) ||
                        s["wParts"].contains(part))
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
                          s["parts"].contains(part) ||
                      s["wParts"].contains(part))
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
                    "${excludeW ? "Exclude" : "Include"} tentative parts"),
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
                      children: people.keys
                          .map((person) =>
                              [_buildListItem(person), new Divider()])
                          .expand((i) => i)
                          .toList())))),
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
                physics: BouncingScrollPhysics(),
                children: _generateDoubleColumnList(),
                padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 0.0),
              )))
    ]);
  }

  Widget _buildListItem(String person) {
    return new CheckboxListTile(
      activeColor: Theme.of(context).accentColor,
      title: new Text(person),
      value: selectedPeople.contains(person),
      onChanged: (bool value) {
        setState(() {
          if (selectedPeople.contains(person)) {
            selectedPeople.remove(person);
          } else {
            selectedPeople.add(person);
          }
        });
      },
    );
  }

  Widget _selectedListItem(String person) {
    return new Expanded(
        child: new Container(child: new Center(child: Text(person))));
  }

  List<Widget> _generateDoubleColumnList() {
    List<Widget> result = [];
    result.add(new ListTile(
        title: new Center(
            child: new Text(
      "${selectedPeople.length} singer${selectedPeople.length == 1 ? "" : "s"} selected",
      style: new TextStyle(
          fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
    ))));

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
    await for (var msg in receivePort) {
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
        showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) {
              return new AlertDialog(
                  title: new Text("Connection Error"),
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
      }
    }
    if (_loading) {
      setState(() {
        _loadingProgress = "";
        _loading = false;
      });
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

  sendPort.send({"type": "progress", "data": "Authenticating"});
  var people = {};
  obtainAccessCredentialsViaServiceAccount(
          _credentials, ["https://spreadsheets.google.com/feeds"], client)
      .then((AccessCredentials credentials) {
    String url =
        "https://spreadsheets.google.com/feeds/cells/13WlZBIQodwZuu4olBTR3UlQJfw06JZ3KWuwQ9Ig9qBE/od6/private/full?min-row=1&max-row=250&return-empty=false";

    sendPort.send({"type": "progress", "data": "Getting spreadsheet data"});
    client.get(url, headers: {
      "Authorization": "Bearer " + credentials.accessToken.data,
      "Gdata-Version": "3.0"
    }).then((response) {
      sendPort.send({"type": "progress", "data": "Parsing cells"});
      var parsed = xml.parse(response.body);
      dynamic cells = parsed.findAllElements("gs:cell");
      cells = cells.map((cell) => new DunavaCell(cell.getAttribute("row"),
          cell.getAttribute("col"), cell.children[0]));
      Map database = {"songs": [], "schemaVersion": databaseVersion};
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

      cells.where((c) => c.col == 1 && c.row > 2).forEach((cell) {
        dynamic song = cell.value;
        sendPort.send({"type": "progress", "data": "$song: Starting"});
        String songName, songSection;
        bool multi = false;
        if (song.contains(' : ')) {
          multi = true;
          song = song.split(' : ');
          songName = song[0];
          songSection = song[1];
        }
        sendPort.send({"type": "progress", "data": "$song: Getting details"});
        var details = cells.where((c) => c.row == cell.row && c.col == 3);
        if (details.length == 0) {
          details = "";
        } else {
          details = details.first.value;
        }
        sendPort
            .send({"type": "progress", "data": "$song: Getting current-ness"});
        var current = cells.where((c) => c.row == cell.row && c.col == 4);
        if (current.length == 0) {
          current = false;
        } else {
          current = true;
        }
        sendPort.send({"type": "progress", "data": "$song: Getting parts"});
        var partsCell = cells.where((c) => c.row == cell.row && c.col == 2);
        List<String> parts;
        if (partsCell.length == 0) {
          parts = [];
        } else {
          parts = partsCell.first.value.split(new RegExp(", *"));
        }
        sendPort
            .send({"type": "progress", "data": "$song: Getting singer parts"});
        var singerParts = {};
        singerNames.forEach((col, _) {
          singerParts[col] =
              cells.where((c) => c.col == col && c.row == cell.row);
        });

        sendPort.send(
            {"type": "progress", "data": "$song: Converting singer parts"});
        singerParts.forEach((col, part) {
          if (part.length > 0) {
            part = part.first;
            if (part.value == "0") {
              singerParts[col] = [];
            } else {
              singerParts[col] = part.value.split(new RegExp(", *"));
            }
          } else {
            singerParts[col] = [];
          }
        });

        sendPort.send(
            {"type": "progress", "data": "$song: Getting singer W parts"});
        var wSingerParts = {};
        singerNames.forEach((col, _) {
          wSingerParts[col] =
              cells.where((c) => c.col == col + 1 && c.row == cell.row);
        });

        sendPort.send(
            {"type": "progress", "data": "$song: Converting singer W parts"});
        wSingerParts.forEach((col, part) {
          if (part.length > 0) {
            part = part.first;
            if (part.value == "0") {
              wSingerParts[col] = [];
            } else {
              wSingerParts[col] = part.value.split(new RegExp(", *"));
            }
          } else {
            wSingerParts[col] = [];
          }
        }); //print(singerParts);

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
      print(database);
    }).catchError((err) {
      print(err);
      sendPort.send({"type": "error", "data": err});
    });
  }).catchError((err) {
    print(err);
    sendPort.send({"type": "error", "data": err});
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
