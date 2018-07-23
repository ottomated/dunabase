import 'package:flutter/material.dart';

import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:googleapis_auth/auth_io.dart';
import "package:http/http.dart" as http;
import "package:xml/xml.dart" as xml;
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'modal_progress_hud.dart';

void main() => runApp(new DunavaApp());

bool themeOn = false;

final spreadsheetUrl =
    'https://docs.google.com/spreadsheets/d/13WlZBIQodwZuu4olBTR3UlQJfw06JZ3KWuwQ9Ig9qBE/';

final _credentials = new ServiceAccountCredentials.fromJson(r'''
{
  "type": "service_account",
  "project_id": "dunava-database",
  "private_key_id": "f5a075cc5501f3a1bd318cb3ce96e9f6f9f9df66",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQChidrrwDL6Phka\ndgT/deBhXC7c3rdmQQufBBQWU5AkzTCnXyrkNLp+MOK3OwEwWP5XUHJs5I50JexQ\nffFN0XW817jRwDORmK2kUgZEWylZRiduP0DppDINYHRnUT2Kgsekc2g9zHgoGTaP\nQ3uIox0u6KlzWEMlXNCXyt9OcTX3odrD/j+8CjJmOdv5wFJheT9yQNWrDOawznzt\nqwV4QFO3CdbL+SFqhuO8f6VVV1PFMJ/uyHWe7Np3CqD+xhKZRVGgIdVmyXS81cXb\nxcI85F3356TBQ6TQgHWxy5OFs9aOX06m1Xcpp1atSuQIP8uoGJqUGHN7gQoN8jDd\n+kRvp629AgMBAAECggEAAlixjSDxgGNaeR1O3+yecduaFZrWtr6810VzsGvsQphb\nIz8FgAjwKSY3DNurh3x2vgsuySWeELRCUWt5CEoytBEImGOgbRRvWftQVN+Q1Dl4\n282cLbAtkk0N4PwV2p3GtMwmXBqBghPWvV89mbHxzrlsZtGrqTJ7kJwwpp3mboUT\nXEA6g0OTp/az6QcwHBNHCSGv9mi/75e15qDIBW9f70r+aXs1FXwFNkiGw63Pm0mu\nXymX0SgWTd+Rhrbysd7cFgjxeJqoT8scRkx8gf/FDO7SlLdlKwtwaVwsZ6ncBM5U\n3lOINTklUFNfycvglpS8NrP9F7g8WAlypxTXe2iaIwKBgQDQVarIZtYwH83x5PV7\njVWy+VaXf7tD1KKUifQdAio9vOCugpb9GSfpvI213uY7RXcSFOBrtf4fbZ4srioc\nNnyqdnPIaY2Kn4Z5zx4pCqa4WAH4E7vl72RuWMYJOpBN1DiHW0D0VNK37ZVO+2/O\nNjCp7h/B/YitaWGEIpW7tKewrwKBgQDGf0yX36eqCTvR+5k8D2DO1wPgEfXBjQoK\nvEoBIqvV+Dv7UjWskzIaDbbbIsvtpL/7IukkxBfWfBpiCBR+JGuSgiMtg+kWW0Cl\nhyWZFN7C/h9+4Wfi7B02BuqJrk46FIQNpT4sBYMUyXFLXmJHlwY7grJtQAPwl4X6\nVICURiQrUwKBgQCKMunRenZHAjIJbopxZTYePUx1vyOoQVuAEWs/+vmubqbU3Ifw\naUmSwaN3q98qHlB4TCT7DoT+sCanGPmSMYrNQTpZDbv44w2/q+cj7o7d5nOX7u9L\n/luu33CvGowzNL4y/BPAgKwvmojbFev67POnJfEnLFoIPsmTb6XIGHTMvQKBgQDD\nGVYQJI0oTIEWiAP6C2dshdvSPfTec6D+IkleylQ5MA7Mm+YTpG3nO7mRs6bbAkaM\nMakUMQT5FOvdlPGHdoag7vZigzfzeGeXCrnCt8enwpz0WdqBKPAhLTUTdFaBMa8F\ntnfgTt6i7MhFexSAJwnCLljvlq8Ip/XQsYPbuQFN7wKBgQCZEzks+T3xjt9rWaHL\n/duidHVgaocNo2+3Ve+2qUX3zzfC5YSwwkSYyxHTyFRBCjk6G9YmwktX/gTDKsmR\nVVv5o3y5o42yL14xDceU+x7v9SE0D9FZeMziYr2g9Xur5FBvtFj1Fa6R5bhnvcKT\nCmC3C+xn5qLSyZdW6f6lfRrvCw==\n-----END PRIVATE KEY-----\n",
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
      var json = new JsonDecoder();
      if (prefs.getKeys().length != 3) {
        _refreshData();
      } else {
        database = json.convert(prefs.getString("data"));
        people = json.convert(prefs.getString("people"));
      }
    });
  }

  void _calculateCombos() {
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
          var results = [];
          doSong(song) {
            print("\n\nDoing ${song["name"]}");
            var arrays = song["singers"].map((s) {
              if (s["parts"].length == 0 ||
                  !selectedPeople.map((p) => people[p]).contains(s["name"])) {
                return [null];
              } else {
                return s["parts"];
              }
            }).toList();
            var perms = cartesianProduct(arrays);
            print("Initial $perms");
            perms = perms.where((perm) {
              var canSing = true;
              if (song["parts"].length == 0) canSing = false;
              for (var part in song["parts"]) {
                print('$part: ${perm.contains(part)}');
                if (!perm.contains(part)) {
                  canSing = false;
                  break;
                }
              }
              print(canSing);
              return canSing;
            });
            print("Final $perms");
            return perms.toList();
          }

          parsePerm(perm) {
            int i = -1;
            perm = perm.map((part) {
              i++;
              return {"name": people.values.elementAt(i), "part": part};
            });
            perm = perm.where((part) => part["part"] != null);
            perm = perm.map((part) => "${part["name"]}: ${part["part"]}");
            return perm.join(", ");
          }

          database["songs"].forEach((song) {
            if (!song["multi"]) {
              var perms = doSong(song);
              if (perms.length > 0) {
                results.add(
                    {"name": song["name"], "details": parsePerm(perms[0])});
              }
            } else {
              song["sections"].forEach((name, section) {
                var perms = doSong(section);
                if (perms.length > 0) {
                  results.add(
                      {"name": "${song["name"]}: $name", "details": parsePerm(perms[0])});
                }
              });
            }
          });
          final tiles = results.map(
            (song) {
              return new ListTile(
                title: new Text(song["name"]),
                subtitle: new Text(song["details"]),
              );
            },
          );
          final divided = ListTile
              .divideTiles(
                context: context,
                tiles: tiles,
              )
              .toList();

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
                    "Enable ${Theme.of(context).brightness == Brightness.dark ? "Light" : "Dark"} Mode"),
                activeColor: Theme.of(context).accentColor,
                onChanged: (bool value) {
                  setState(() {
                    DynamicTheme.of(context).setBrightness(
                        Theme.of(context).brightness == Brightness.dark
                            ? Brightness.light
                            : Brightness.dark);
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

  Future<Null> _handleRefresh() {
    final Completer<Null> completer = new Completer<Null>();
    new Timer(const Duration(seconds: 3), () {
      completer.complete(null);
    });
    return completer.future.then((_) {});
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
            context: context,
            builder: (BuildContext context) {
              return new AlertDialog(
                title: new Text("Connection Error"),
                content: new Text("${data["data"]}"),
              );
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
        return;
      }
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
      var database = {"songs": []};
      var singerNames = {};
      cells
          .where((c) =>
              c.row == 2 &&
              c.col > 2 &&
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
            {"type": "progress", "data": "$song: Normalizing singer parts"});
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
        //print(singerParts);

        var singers = [];

        singerNames.forEach((col, name) {
          singers.add({"name": name, "parts": singerParts[col]});
        });

        sendPort.send(
            {"type": "progress", "data": "$song: Adding song to database"});
        if (database["songs"].map((s) => s["name"]).contains(songName)) {
          var existingSong =
              database["songs"].firstWhere((s) => s["name"] == songName);
          existingSong["sections"]
              [songSection] = {"parts": parts, "singers": singers};
        } else {
          if (!multi) {
            database["songs"].add({
              "name": song,
              "parts": parts,
              "multi": false,
              "singers": singers
            });
          } else {
            database["songs"].add({
              "name": songName,
              "multi": true,
              "sections": {
                songSection: {"parts": parts, "singers": singers}
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
