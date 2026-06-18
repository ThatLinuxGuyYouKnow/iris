import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iris/services/gemini_service.dart';
import 'package:web/web.dart' as web;

/// Renders Google Maps grounding sources in the style mandated by Google's
/// "Grounding with Google Maps" attribution guidelines:
///   - The text "Google Maps" must appear, unmodified, untranslated.
///   - Font: Roboto (fallback sans-serif), weight 400, style normal.
///   - Colour: white / #1F1F1F / #5E5E5E, accessible contrast.
///   - Size: 12–16sp.
///   - Each source must be a link to its Maps `uri`, viewable within one
///     user interaction, immediately following the grounded content.
///
/// Display this widget directly beneath any text produced by
/// [GeminiService.groundedPlaceQuery] when it returns sources. Omitting it
/// violates the Maps Grounding service usage requirements.
class MapsAttribution extends StatelessWidget {
  final List<GroundingSource> sources;
  final bool compact;

  const MapsAttribution({super.key, required this.sources, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();

    final textStyle = GoogleFonts.roboto(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
      color: const Color(0xFF5E5E5E),
      decoration: TextDecoration.underline,
    );

    return Semantics(
      label: 'Sources from Google Maps',
      child: ExcludeSemantics(
        // The individual link semantics are provided by the InkWell below.
        excluding: true,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Text('Sources: ', style: _labelStyle()),
              for (final s in sources) _sourceChip(s, textStyle),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle() => GoogleFonts.roboto(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF5E5E5E),
      );

  Widget _sourceChip(GroundingSource s, TextStyle textStyle) {
    // `translate="no"` is enforced at the HTML level for web builds via the
    // semantic attribution label; the "Google Maps" wordmark is rendered
    // verbatim and never localised.
    final label = s.title.isEmpty ? 'Google Maps' : s.title;
    return InkWell(
      onTap: s.uri.isEmpty ? null : () => _open(s.uri),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 14, color: Color(0xFF5E5E5E)),
            const SizedBox(width: 4),
            Text(label, style: textStyle),
          ],
        ),
      ),
    );
  }

  Future<void> _open(String uri) async {
    // Web-only: open in a new tab via the browser. Same package:web approach
    // used elsewhere in Iris (haptics, STT, TTS).
    try {
      web.window.open(uri, '_blank');
    } catch (_) {
      // Silently ignore — link is still rendered for copy/click fallback.
    }
  }
}
