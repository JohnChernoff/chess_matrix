import 'package:flutter/material.dart';
import 'package:lichess_package/lichess_package.dart';
import 'client.dart';
import 'dialogs.dart';
import 'main.dart';

class SeekWidget extends StatefulWidget {
  final MatrixClient client;
  const SeekWidget(this.client,{super.key});

  @override
  State<StatefulWidget> createState() => _SeekWidgetState();

}

const List<BasicSeek> pools = [
  BasicSeek(10,0,true),
  BasicSeek(10,5,true),
  BasicSeek(15,10,true),
  BasicSeek(30,0,true),
  BasicSeek(30,20,true),
];

class BasicSeek {
  final int minutes, inc;
  final bool rated;
  const BasicSeek(this.minutes,this.inc,this.rated);
}

class _SeekWidgetState extends State<SeekWidget> {
  int minutes = 8, inc = 0;
  int? minRating, maxRating;
  bool rated = false, ratingRanges = false;
  BasicSeek? pool;

  double iniMinRating(int rating) => (minRating ?? (rating - 500)) as double;
  double iniMaxRating(int rating) => (maxRating ?? (rating + 500)) as double;

  @override
  Widget build(BuildContext context) {
    int rating = widget.client.getRating(minutes as double,inc);
    return Container(color: Colors.grey, height: 480, child: Center(child: Column(children: [
      Row(children: [
        Text("Rated Pool: ",style: MatrixApp.getTextStyle(Colors.black)),
        DropdownButton(
            value: pool,
            items: List.generate(pools.length, (index) => DropdownMenuItem<BasicSeek>(value: pools[index],
                child: Text("${pools[index].minutes}/${pools[index].inc}")),
            ), onChanged: (v) {
          setState(() {
            if (v != null) {
              minutes = v.minutes;
              inc = v.inc;
              rated = true;
              ratingRanges = false;
              pool = v;
            }
          });
        }),
      ]),
      Row(
        children: [
          Text("Minutes: $minutes",style: MatrixApp.getTextStyle(Colors.black)),
          Slider(value: minutes as double, min: 8, max: 60, divisions: 52,
              onChanged: (v) => setState(() {
                minutes = v.floor();
              })),
        ],
      ),
      Row(
        children: [
          Text("Inc: $inc",style: MatrixApp.getTextStyle(Colors.black)),
          Slider(value: inc as double, min: 0, max: 30,
              onChanged: (v) => setState(() {
                inc = v.floor();
              })),
        ],
      ),
      Row(children: [
        Text("Rating Ranges",style: MatrixApp.getTextStyle(Colors.black)),
        Checkbox(value: ratingRanges, onChanged: (b) => setState(() {
          ratingRanges = b ?? false;
        })),
      ]),
      ratingRanges ? Row(
        children: [
          Text("Min Rating: ${iniMinRating(rating)}",style: MatrixApp.getTextStyle(Colors.black)),
          Slider(value: iniMinRating(rating), min: (rating - 500), max: rating as double,
              onChanged: (v) => setState(() {
                minRating = v.floor();
              })),
        ],
      ) : const SizedBox.shrink(),
      ratingRanges ? Row(
        children: [
          Text("Max Rating: ${iniMaxRating(rating)}",style: MatrixApp.getTextStyle(Colors.black)),
          Slider(value: iniMaxRating(rating), min: rating as double, max: (rating + 500),
              onChanged: (v) => setState(() {
                maxRating = v.floor();
              })),
        ],
      ) : const SizedBox.shrink(),
      Row(
        children: [
          Text("Rated",style: MatrixApp.getTextStyle(Colors.black)),
          Checkbox(value: rated, onChanged: (b) => setState(() {
            rated = b ?? false;
          })),
        ],
      ),
      const Divider(height: 32),
      ElevatedButton(onPressed: () {
        widget.client.seekGame(minutes,inc: inc,rated: rated, min: ratingRanges ? minRating : null, max: ratingRanges ? maxRating : null);
        Navigator.of(context).pop();
      }, child: Text("Seek ${LichessClient.getRatingType(minutes as double, inc)?.name}",style: MatrixApp.getTextStyle(Colors.black))),
      const Divider(height: 32),
      ElevatedButton(onPressed: () {
        ChallengeDialog(context,widget.client,minutes * 60,inc,rated).raise().then((b) {
          if (context.mounted && (b ?? false)) InfoDialog(context,"Challege Created!").raise();
        });
      },
        child: Text("Challenge",style: MatrixApp.getTextStyle(Colors.black))),
    ],
    )));
  }

}