import 'dart:async'; // Import the Timer class
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

void main() {
  runApp(ClockApp());
}

class ClockApp extends StatefulWidget {
  @override
    _ClockAppState createState() => _ClockAppState();
}

class _ClockAppState extends State<ClockApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _ToggleButtonsTheme()
  {
  setState(() {
    if(_themeMode == ThemeMode.light){
      _themeMode=ThemeMode.dark;
    }
    else if(_themeMode == ThemeMode.dark){
      _themeMode= ThemeMode.system;
    }
    else{
      _themeMode=ThemeMode.light;
    }
    
  });
}

@override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clock App',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode, // Default to system theme
      home: ClockHomePage(onThemeToggle: _ToggleButtonsTheme),
    );
  }
}


class ClockHomePage extends StatefulWidget {
  final VoidCallback onThemeToggle;

  ClockHomePage({required this.onThemeToggle});
  @override
  _ClockHomePageState createState() => _ClockHomePageState();
}

class _ClockHomePageState extends State<ClockHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Duration _duration = Duration(minutes: 1); // Default duration is 1 minute
  Timer? _timer;
  Timer? _stopwatchTimer;
  List<String> _laps = [];
  bool _isStopwatchRunning = false;
  Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer?.cancel();
    _stopwatchTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
        if (_duration.inSeconds > 0) {
          setState(() {
            _duration = _duration - Duration(seconds: 1);
          });
        } else {
          Vibrate.vibrate();
          timer.cancel();
        }
      });
    });
  }

  void _pickTimerDuration(BuildContext context) async {
    final Duration? selectedDuration = await showDialog<Duration>(
      context: context,
      builder: (BuildContext context) {
        int? minutes;
        int? seconds;
        return AlertDialog(
          title: Text('Set Timer Duration'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Minutes"),
                onChanged: (value) {
                  minutes = int.tryParse(value);
                },
              ),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Seconds"),
                onChanged: (value) {
                  seconds = int.tryParse(value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (minutes == null) minutes = 0;
                if (seconds == null) seconds = 0;
                Navigator.of(context).pop(Duration(
                  minutes: minutes!,
                  seconds: seconds!,
                ));
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );

    if (selectedDuration != null && selectedDuration.inSeconds > 0) {
      setState(() {
        _duration = selectedDuration;
      });
    }
  }

  void _startStopwatch() {
    setState(() {
      _isStopwatchRunning = true;
      _stopwatch.start();
      _stopwatchTimer = Timer.periodic(Duration(milliseconds: 30), (Timer timer) {
        setState(() {});
      });
    });
  }

  void _stopStopwatch() {
    setState(() {
      _isStopwatchRunning = false;
      _stopwatch.stop();
      _stopwatchTimer?.cancel();
    });
  }

  void _resetStopwatch() {
    setState(() {
      _stopwatch.reset();
      _laps.clear(); // Clear laps when resetting
    });
  }

  void _recordLap() {
    setState(() {
      _laps.add(_stopwatch.elapsed.toString().split('.').first + '.' + _stopwatch.elapsed.toString().split('.').last.padRight(3, '0'));
    });
  }

  Widget _buildClockSection() {
    return Center(
      child: Text(
        '${TimeOfDay.now().format(context)}',
        style: TextStyle(fontSize: 48),
      ),
    );
  }

  Widget _buildTimerSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: _duration.inSeconds / 60,
                  strokeWidth: 10,
                  color: _duration.inSeconds <= 10
                      ? (_duration.inSeconds % 2 == 0
                          ? const Color.fromARGB(255, 255, 77, 65)
                          : const Color.fromARGB(255, 246, 255, 0))
                      : const Color.fromARGB(255, 206, 189, 137),
                ),
              ),
              Text(
                "${_duration.inMinutes.toString().padLeft(2, '0')}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}",
                style: TextStyle(fontSize: 48),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (_timer == null || !_timer!.isActive) {
                    _startTimer();
                  } else {
                    _timer?.cancel();
                  }
                  HapticFeedback.mediumImpact();
                },
                child: Text(_timer?.isActive == true ? 'Stop Timer' : 'Start Timer'),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                  _pickTimerDuration(context);
                },
                child: Text('Set Timer Duration'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStopwatchSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _stopwatch.elapsed.toString().split('.').first + '.' + _stopwatch.elapsed.toString().split('.').last.padRight(3, '0'), // Display milliseconds
          style: TextStyle(fontSize: 48),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isStopwatchRunning ? _stopStopwatch : _startStopwatch,
              child: Text(_isStopwatchRunning ? 'Stop' : 'Start'),
            ),
            SizedBox(width: 20),
            ElevatedButton(
              onPressed: _recordLap,
              child: Text('Lap'),
            ),
            SizedBox(width: 20),
            if (!_isStopwatchRunning && _stopwatch.elapsedMilliseconds > 0)
              ElevatedButton(
                onPressed: _resetStopwatch,
                child: Text('Reset'),
              ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _laps.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('Lap ${index + 1}: ${_laps[index]}'),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clock App'),
      
          actions: [
            IconButton(
              icon: Icon(Icons.brightness_6_outlined),
              onPressed: widget.onThemeToggle,),
          ],
          bottom: TabBar(
            controller: _tabController,
          tabs: [
            Tab(text: 'Clock'),
            Tab(text: 'Timer'),
            Tab(text: 'Stopwatch'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildClockSection(),
          _buildTimerSection(),
          _buildStopwatchSection(),
        ],
      ),
    );
  }
}
