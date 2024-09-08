\version "2.25.18"
\include "fontnormalize.ly"

\layout {
  \context {
    \Global
    \normalizeOpticalTextSizes
  }
}

\paper {
  property-defaults.fonts.serif-caption = "Arno Pro Regular 08pt"
  fonts-info.serif-caption.normalize-to = #'(x-height . default-serif)
  property-defaults.fonts.serif-small = "Arno Pro Regular 10pt"
  fonts-info.serif-small.normalize-to = #'(x-height . default-serif)
  property-defaults.fonts.serif-regular = "Arno Pro 12pt"
  fonts-info.serif-regular.normalize-to = #'(x-height . default-serif)
  property-defaults.fonts.serif-subhead = "Arno Pro Regular 18pt"
  fonts-info.serif-subhead.normalize-to = #'(x-height . default-serif)
  property-defaults.fonts.serif-display = "Arno Pro Regular 36pt"
  fonts-info.serif-display.normalize-to = #'(x-height . default-serif)
  fonts-info.serif.optical-sizes = #'(((-inf.0 . 8.5) . caption)
                                      ((8.5 . 11) . small)
                                      ((11 . 14) . regular)
                                      ((14 . 21.5) . subhead)
                                      ((21.5 . +inf.0) . display))
}

#(set-global-staff-size 22)

\markup "bar"

{ c'1^\markup "bar" }

#(ly:message "~a" (ly:font-config-get-font-file "Arno Pro"))