# Lilypond normalized optical text sizes via Scheme

This is a Scheme implementation of:
* Automatical size adjustments to match a specified height metric (`x-height`, `cap-height`, or custom character height) of a text font family against either a reference text font family or a reference height measured in staff spaces.
* Automatic selection of appropriate optical font family variants (such as those offered by Adobe fonts) based on specified point size ranges.
* A context-mod `\normalizeOpticalTextSizes` for either the `\Global` or `\Score` level that enables these features.

See `tests.ly` for a usage example with an open source font family.

Note that this implementation relies on adding multiple lightweight procedures to `string-transformers`, and this will add significant performance overhead by scaling the number of function calls required to render *every* markup. It would be better to implement this via a patch to Lilypond's internal text font handling. For that reason, this should be considered experimental (though I have found it works well enough for my personal use).
