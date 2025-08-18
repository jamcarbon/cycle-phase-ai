import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:io';

// Entry point
void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cycle Phase Coach (AI)',
      theme: ThemeData(useMaterial3: true),
      home: const InputScreen(),
    );
  }
}

class Config {
  // In-memory configuration values edited in ConfigScreen
  String model;
  String proxyUrl;
  String apiKey;
  double temperature;
  double topP;
  int topK;
  int maxTokens;
  String systemPrompt;
  String language;
  double directness;
  double humor;
  double warmth;
  String style;
  int alternatives;
  String disallowTopics;
  bool cautionMode;
  bool addNotSay;
  String userVibe;
  String budget;
  String timeOfDay;
  String city;
  Config({
    this.model = 'gemini-1.5-flash',
    this.proxyUrl = '',
    this.apiKey = '',
    this.temperature = 0.7,
    this.topP = 0.95,
    this.topK = 40,
    this.maxTokens = 512,
    this.systemPrompt = defaultSystemPrompt,
    this.language = 'English',
    this.directness = 0.5,
    this.humor = 0.3,
    this.warmth = 0.8,
    this.style = 'respectful, concise, confident, playful-not-cheesy',
    this.alternatives = 2,
    this.disallowTopics =
        'medical claims, explicit sexual detail, body shaming, manipulation',
    this.cautionMode = true,
    this.addNotSay = true,
    this.userVibe = '',
    this.budget = 'medium',
    this.timeOfDay = 'evening',
    this.city = '',
  });
  Config copy() => Config(
    model: model,
    proxyUrl: proxyUrl,
    apiKey: apiKey,
    temperature: temperature,
    topP: topP,
    topK: topK,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
    language: language,
    directness: directness,
    humor: humor,
    warmth: warmth,
    style: style,
    alternatives: alternatives,
    disallowTopics: disallowTopics,
    cautionMode: cautionMode,
    addNotSay: addNotSay,
    userVibe: userVibe,
    budget: budget,
    timeOfDay: timeOfDay,
    city: city,
  );
}

const defaultSystemPrompt =
    'You are "Cycle Phase Coach", a respectful, concise assistant that tailors social and dating guidance to the user\'s selected contexts and an estimated menstrual phase computed on-device.\nHard rules:\n- Never give medical advice or diagnoses.\n- Always emphasize consent, empathy, and boundaries.\n- Avoid manipulation, coercion, or sexual pressure.\n- Be culturally sensitive, PG-13, and non-crude.\n- Use crisp, concrete suggestions; avoid clichés.\n- Keep outputs short and skimmable (bullets + one-liners).\n- When phase suggests lower energy, prioritize comfort and low-friction options.\n- If user context is inappropriate for the phase, gently offer safer alternatives.\n- Include a brief disclaimer: "People vary; always ask and respect her comfort."';

const phaseEmoji = {
  'Menstrual': '🩸',
  'Follicular': '🌱',
  'Ovulatory': '✨',
  'Luteal': '🌙',
};

const allContexts = [
  'Date',
  'Bar pick-up',
  'Girlfriend',
  'Text / DM opener',
  'First date',
  'Daytime coffee / lunch',
  'Night-in / cook at home',
  'Active / walk / workout',
  'Social event / meet friends',
  'Repair / after a disagreement',
];

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});
  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  DateTime? lmp;
  final TextEditingController cycleCtrl = TextEditingController(text: '28');
  Config config = Config();

  int get cycleLength => int.tryParse(cycleCtrl.text) ?? 28;

  // Pick LMP date using the date picker
  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDate: lmp ?? now,
    );
    if (picked != null) {
      setState(() => lmp = picked);
    }
  }

  // Navigate to configuration screen
  void _openConfig() async {
    final result = await Navigator.push<Config>(
      context,
      MaterialPageRoute(builder: (_) => ConfigScreen(config.copy())),
    );
    if (result != null) setState(() => config = result);
  }

  // Validate and go to context selection
  void _next() {
    final len = cycleLength;
    if (len < 21 || len > 35) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cycle length must be 21-35 days')),
      );
      return;
    }
    if (lmp == null) return;
    final daysSinceLmp = DateTime.now().difference(lmp!).inDays + 1;
    if (daysSinceLmp <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('LMP must be before today')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ContextScreen(lmp: lmp!, cycleLength: len, config: config),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cycle Phase Coach')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: const Text('Select LMP'),
                subtitle: Text(
                  lmp == null
                      ? 'Pick date'
                      : lmp!.toIso8601String().split('T').first,
                ),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('Cycle length'),
                subtitle: TextField(
                  controller: cycleCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _openConfig,
                  child: const Text('Configuration'),
                ),
                ElevatedButton(
                  onPressed: lmp == null ? null : _next,
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ConfigScreen extends StatefulWidget {
  final Config config;
  const ConfigScreen(this.config, {super.key});
  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  late Config cfg;
  @override
  void initState() {
    super.initState();
    cfg = widget.config;
  }

  // Helper for sliders controlling numeric values
  Widget _numField(
    String label,
    double value,
    Function(double) onChanged, {
    double min = 0,
    double max = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: (v) => setState(() => onChanged(v)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI / Model',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: TextEditingController(text: cfg.model),
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Model'),
            ),
            TextField(
              controller: TextEditingController(text: cfg.proxyUrl),
              decoration: const InputDecoration(labelText: 'Proxy URL'),
              onChanged: (v) => cfg.proxyUrl = v,
            ),
            TextField(
              controller: TextEditingController(text: cfg.apiKey),
              decoration: const InputDecoration(labelText: 'API Key'),
              obscureText: true,
              onChanged: (v) => cfg.apiKey = v,
            ),
            _numField(
              'Temperature',
              cfg.temperature,
              (v) => cfg.temperature = v,
            ),
            _numField('topP', cfg.topP, (v) => cfg.topP = v),
            _numField(
              'topK',
              cfg.topK.toDouble(),
              (v) => cfg.topK = v.round(),
              min: 1,
              max: 100,
            ),
            _numField(
              'maxTokens',
              cfg.maxTokens.toDouble(),
              (v) => cfg.maxTokens = v.round(),
              min: 64,
              max: 1024,
            ),
            const SizedBox(height: 16),
            const Text(
              'System Prompt',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: TextEditingController(text: cfg.systemPrompt),
              maxLines: 8,
              onChanged: (v) => cfg.systemPrompt = v,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tone & Style',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: TextEditingController(text: cfg.language),
              decoration: const InputDecoration(labelText: 'Language'),
              onChanged: (v) => cfg.language = v,
            ),
            _numField('Directness', cfg.directness, (v) => cfg.directness = v),
            _numField('Humor', cfg.humor, (v) => cfg.humor = v),
            _numField('Warmth', cfg.warmth, (v) => cfg.warmth = v),
            TextField(
              controller: TextEditingController(text: cfg.style),
              decoration: const InputDecoration(labelText: 'Style keywords'),
              onChanged: (v) => cfg.style = v,
            ),
            TextField(
              controller: TextEditingController(
                text: cfg.alternatives.toString(),
              ),
              decoration: const InputDecoration(
                labelText: 'Alternatives per context',
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) =>
                  cfg.alternatives = int.tryParse(v) ?? cfg.alternatives,
            ),
            const SizedBox(height: 16),
            const Text(
              'Boundaries & Safety',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: TextEditingController(text: cfg.disallowTopics),
              decoration: const InputDecoration(labelText: 'Disallow topics'),
              onChanged: (v) => cfg.disallowTopics = v,
            ),
            SwitchListTile(
              title: const Text('Caution mode in Menstrual/Luteal'),
              value: cfg.cautionMode,
              onChanged: (v) => setState(() => cfg.cautionMode = v),
            ),
            SwitchListTile(
              title: const Text('Add "What NOT to say" section'),
              value: cfg.addNotSay,
              onChanged: (v) => setState(() => cfg.addNotSay = v),
            ),
            const SizedBox(height: 16),
            const Text(
              'Personalization (optional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: TextEditingController(text: cfg.userVibe),
              decoration: const InputDecoration(
                labelText: 'User vibe keywords',
              ),
              onChanged: (v) => cfg.userVibe = v,
            ),
            DropdownButtonFormField(
              value: cfg.budget,
              decoration: const InputDecoration(labelText: 'Default budget'),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('low')),
                DropdownMenuItem(value: 'medium', child: Text('medium')),
                DropdownMenuItem(value: 'high', child: Text('high')),
              ],
              onChanged: (v) => cfg.budget = v ?? 'medium',
            ),
            DropdownButtonFormField(
              value: cfg.timeOfDay,
              decoration: const InputDecoration(labelText: 'Time of day'),
              items: const [
                DropdownMenuItem(value: 'day', child: Text('day')),
                DropdownMenuItem(value: 'evening', child: Text('evening')),
                DropdownMenuItem(value: 'late', child: Text('late')),
              ],
              onChanged: (v) => cfg.timeOfDay = v ?? 'evening',
            ),
            TextField(
              controller: TextEditingController(text: cfg.city),
              decoration: const InputDecoration(labelText: 'City/region'),
              onChanged: (v) => cfg.city = v,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, cfg),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ContextScreen extends StatefulWidget {
  final DateTime lmp;
  final int cycleLength;
  final Config config;
  const ContextScreen({
    super.key,
    required this.lmp,
    required this.cycleLength,
    required this.config,
  });
  @override
  State<ContextScreen> createState() => _ContextScreenState();
}

class _ContextScreenState extends State<ContextScreen> {
  final Set<String> selected = {};

  int get cycleDay =>
      computeCycleDay(widget.lmp, widget.cycleLength, DateTime.now());
  String get phase => determinePhase(cycleDay, widget.cycleLength);
  int get daysSinceLmp => DateTime.now().difference(widget.lmp).inDays + 1;

  // Proceed to fetch advice
  void _calculate() {
    if (selected.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OutputScreen(
          lmp: widget.lmp,
          cycleLength: widget.cycleLength,
          cycleDay: cycleDay,
          phase: phase,
          contexts: selected.toList(),
          config: widget.config,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Contexts')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade200,
            child: Text(
              '${phaseEmoji[phase]}  $phase – Day $cycleDay of ${widget.cycleLength}',
            ),
          ),
          if (daysSinceLmp > 90)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.amber,
              child: const Text('Cycles vary; results may be inaccurate.'),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final c in allContexts)
                    FilterChip(
                      label: Text(c),
                      selected: selected.contains(c),
                      onSelected: (v) => setState(() {
                        if (v) {
                          selected.add(c);
                        } else {
                          selected.remove(c);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: selected.isEmpty ? null : _calculate,
              child: const Text('Calculate'),
            ),
          ),
        ],
      ),
    );
  }
}

class OutputScreen extends StatefulWidget {
  final DateTime lmp;
  final int cycleLength;
  final int cycleDay;
  final String phase;
  final List<String> contexts;
  final Config config;
  const OutputScreen({
    super.key,
    required this.lmp,
    required this.cycleLength,
    required this.cycleDay,
    required this.phase,
    required this.contexts,
    required this.config,
  });
  @override
  State<OutputScreen> createState() => _OutputScreenState();
}

class _OutputScreenState extends State<OutputScreen> {
  bool loading = true;
  bool usedFallback = false;
  Map<String, Map<String, List<String>>> advice = {};

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  // Call Gemini or fallback to local templates
  Future<void> _fetch() async {
    setState(() {
      loading = true;
      usedFallback = false;
    });
    final prompt = buildPrompt(
      widget.lmp,
      widget.cycleLength,
      widget.cycleDay,
      widget.phase,
      widget.contexts,
      widget.config,
    );
    String? text;
    if (widget.config.apiKey.isNotEmpty || widget.config.proxyUrl.isNotEmpty) {
      text = await callGemini(prompt, widget.config);
    }
    if (text != null) {
      try {
        final parsed = jsonDecode(text) as Map<String, dynamic>;
        parsed.forEach((k, v) {
          advice[k] = {
            'do': List<String>.from(v['do'] ?? []),
            'say': List<String>.from(v['say'] ?? []),
            'not': List<String>.from(v['not'] ?? []),
            'body': List<String>.from(v['body'] ?? []),
            'backup': List<String>.from(v['backup'] ?? []),
          };
        });
      } catch (_) {
        usedFallback = true;
      }
    } else {
      usedFallback = true;
    }
    if (usedFallback) {
      for (final c in widget.contexts) {
        advice[c] = fallbackFor(widget.phase, c, widget.config);
      }
    }
    setState(() => loading = false);
  }

  // Copy all sections to clipboard
  void _copyAll() {
    final buffer = StringBuffer();
    advice.forEach((ctx, data) {
      buffer.writeln(ctx);
      data.forEach((k, v) {
        if (v.isEmpty) return;
        buffer.writeln('$k:');
        for (final line in v) {
          buffer.writeln('- $line');
        }
      });
      buffer.writeln();
    });
    buffer.writeln(
      'Informational only; not medical advice. People vary; always respect boundaries and consent.',
    );
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advice')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey.shade200,
                  child: Text(
                    '${phaseEmoji[widget.phase]} ${widget.phase} – Day ${widget.cycleDay} of ${widget.cycleLength}',
                  ),
                ),
                if (usedFallback)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.red.shade100,
                    child: const Text('AI unavailable; using fallback.'),
                  ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final ctx in advice.keys)
                        ExpansionTile(
                          title: Text(ctx),
                          children: [
                            for (final entry in advice[ctx]!.entries)
                              if (entry.value.isNotEmpty)
                                _section(entry.key, entry.value),
                            const SizedBox(height: 8),
                            const Text(
                              'People vary; ask and respect her comfort.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _fetch,
                      child: const Text('Regenerate'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back'),
                    ),
                    ElevatedButton(
                      onPressed: _copyAll,
                      child: const Text('Copy All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Informational only; not medical advice. People vary; always respect boundaries and consent.',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
    );
  }

  // Render a single section with copy button
  Widget _section(String title, List<String> lines) {
    final text = lines.map((e) => '- $e').join('\n');
    return ListTile(
      title: Text(title),
      subtitle: Text(text),
      trailing: IconButton(
        icon: const Icon(Icons.copy),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: text));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Copied')));
        },
      ),
    );
  }
}

// Compute current cycle day
int computeCycleDay(DateTime lmp, int cycleLen, DateTime now) {
  final days = now.difference(lmp).inDays + 1;
  return ((days - 1) % cycleLen) + 1;
}

// Map cycle day to phase name
String determinePhase(int day, int cycleLen) {
  if (day <= 5) return 'Menstrual';
  if (day <= 13) return 'Follicular';
  if (day <= 17) return 'Ovulatory';
  return 'Luteal';
}

// Assemble full prompt sent to Gemini
String buildPrompt(
  DateTime lmp,
  int cycleLen,
  int day,
  String phase,
  List<String> contexts,
  Config cfg,
) {
  final now = DateTime.now();
  final buf = StringBuffer();
  buf.writeln('[SYSTEM]: ${cfg.systemPrompt}');
  buf.writeln();
  buf.writeln('[APP CONTEXT]');
  buf.writeln('Inputs:');
  buf.writeln(
    '- LMP: ${lmp.toIso8601String().split('T').first}   Cycle length: $cycleLen   Today: ${now.toIso8601String().split('T').first}',
  );
  buf.writeln('- Computed cycle day: $day of $cycleLen');
  buf.writeln('- Phase: $phase');
  buf.writeln('- Caution mode: ${cfg.cautionMode ? 'ON' : 'OFF'}');
  buf.writeln(
    '- Language: ${cfg.language}   Tone: directness=${cfg.directness.toStringAsFixed(2)}, humor=${cfg.humor.toStringAsFixed(2)}, warmth=${cfg.warmth.toStringAsFixed(2)}',
  );
  buf.writeln('- Style: ${cfg.style}');
  buf.writeln(
    '- Personalization: vibe=${cfg.userVibe}, budget=${cfg.budget}, timeOfDay=${cfg.timeOfDay}, city=${cfg.city}',
  );
  buf.writeln('- Disallow topics: ${cfg.disallowTopics}');
  buf.writeln('- Alternatives per context: ${cfg.alternatives}');
  buf.writeln();
  buf.writeln('[CONTEXTS SELECTED]');
  for (final c in contexts) {
    buf.writeln('- $c');
  }
  buf.writeln();
  buf.writeln('[TASK]');
  buf.writeln(
    'For EACH selected context, produce JSON with keys: "do", "say", "not", "body", "backup". Each is a list of strings. Keep each context under ~120 words.',
  );
  buf.writeln('Return ONLY JSON.');
  return buf.toString();
}

DateTime? _lastCall;
// Perform REST call to Gemini (or proxy)
Future<String?> callGemini(String prompt, Config cfg) async {
  final now = DateTime.now();
  if (_lastCall != null) {
    final diff = now.difference(_lastCall!);
    if (diff.inMilliseconds < 2000) {
      await Future.delayed(Duration(milliseconds: 2000 - diff.inMilliseconds));
    }
  }
  _lastCall = DateTime.now();
  try {
    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': cfg.temperature,
        'topP': cfg.topP,
        'topK': cfg.topK,
        'maxOutputTokens': cfg.maxTokens,
      },
    });
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);
    HttpClientRequest req;
    if (cfg.proxyUrl.isNotEmpty) {
      req = await client.postUrl(Uri.parse(cfg.proxyUrl));
      req.headers.contentType = ContentType.json;
      req.add(utf8.encode(jsonEncode({'request': body})));
    } else {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/${cfg.model}:generateContent?key=${cfg.apiKey}',
      );
      req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.add(utf8.encode(body));
    }
    final res = await req.close().timeout(const Duration(seconds: 20));
    final str = await res.transform(utf8.decoder).join();
    if (res.statusCode == 200) {
      final jsonMap = jsonDecode(
        cfg.proxyUrl.isNotEmpty ? jsonDecode(str) : str,
      );
      final txt = jsonMap['candidates'][0]['content']['parts'][0]['text'];
      return txt;
    }
  } catch (_) {}
  return null;
}

// Local deterministic advice when AI unavailable
Map<String, List<String>> fallbackFor(String phase, String ctx, Config cfg) {
  final descriptors = {
    'Menstrual': {
      'activity': 'low-key',
      'tone': 'comfort-first',
      'body': 'Relaxed posture',
      'backup': 'quiet tea spot',
    },
    'Follicular': {
      'activity': 'new and playful',
      'tone': 'adventurous',
      'body': 'Open body language',
      'backup': 'stroll in park',
    },
    'Ovulatory': {
      'activity': 'lively',
      'tone': 'confident',
      'body': 'Friendly eye contact',
      'backup': 'meet friends nearby',
    },
    'Luteal': {
      'activity': 'calm',
      'tone': 'reassuring',
      'body': 'Soft gestures',
      'backup': 'movie at home',
    },
  }[phase]!;
  return {
    'do': [
      'Plan a ${descriptors['activity']} ${ctx.toLowerCase()}',
      'Check in on comfort levels',
      'Keep it ${descriptors['tone']}',
    ],
    'say': [
      '"How about a ${descriptors['activity']} ${ctx.toLowerCase()}?"',
      '"Let me know what feels right."',
    ],
    'not': ['Pushy comments', 'Medical advice', 'Anything disrespectful'],
    'body': [descriptors['body']!],
    'backup': [descriptors['backup']!],
  };
}
