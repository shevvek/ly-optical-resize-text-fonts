\version "2.25.18"
\include "fontnormalize.ily"

\layout {
  \context {
    \Global
    \normalizeOpticalTextSizes
  }
}

\paper {
  property-defaults.fonts.serif-caption = "Source Serif 4 Caption"
  fonts-info.serif-caption.normalize-to = #'(x-height . default-serif)
  property-defaults.fonts.serif-small = "Source Serif 4 SmText"
  fonts-info.serif-small.normalize-to = #'(x-height . default-serif)
  property-defaults.fonts.serif-regular = "Source Serif 4"
  fonts-info.serif-regular.normalize-to = #'(x-height . default-serif)
  property-defaults.fonts.serif-subhead = "Source Serif 4 Subhead"
  fonts-info.serif-subhead.normalize-to = #'(x-height . default-serif)
  property-defaults.fonts.serif-display = "Source Serif 4 Display"
  fonts-info.serif-display.normalize-to = #'(x-height . default-serif)
  fonts-info.serif.optical-sizes = #'(((0 . 9) . caption)
                                      ((9 . 14) . small)
                                      ((14 . 22) . regular)
                                      ((22 . 42) . subhead)
                                      ((42 . +inf.0) . display))
}

#(set-global-staff-size 22)

\markup "bar"

{ c'1^\markup "bar" }

% This can be helpful in determining the names of optical variant families
#(ly:message "~a" (ly:font-config-get-font-file "Source Serif 4"))
