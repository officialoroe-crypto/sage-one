# Nine-Beat Transition Keyframe Sheet

**Example:** Bronze High → Silver Low  
**Status:** Storyboard specification, not final animation timing.  
**Rule:** Keep the SAGE emblem and permanent blue/black identity recognizable throughout.

| Beat | Visual keyframe | Outgoing Bronze High | Incoming Silver Low | Review condition |
|---:|---|---|---|---|
| 1 | Particles accelerate | Copper fragments move faster and tighten their paths | Not yet visible | No particle crosses or obscures the SAGE wordmark/emblem |
| 2 | Energy concentrates | Bronze light and fragments converge toward the emblem | A faint cool-white core may begin to appear | The focal point remains centered and stable |
| 3 | Screen darkens | Background scene and panels dim briefly | No strong Silver reveal yet | Labels and core emblem remain discernible |
| 4 | Shockwave / burst | One controlled pulse releases the old material | Silver light begins at the pulse boundary | Single readable pulse; no repeated flash |
| 5 | Old material breaks | Bronze facets separate and disperse | Silver remains restrained | Bronze clearly exits; no muddy bronze/silver blend |
| 6 | New material forms | Only residual fragments remain | Silver facets assemble in the same emblem footprint | Incoming geometry matches the established emblem alignment |
| 7 | New particles appear | Bronze particles fade out | Sparse Silver particles appear | Particle color/material is distinct but not a full-screen recolor |
| 8 | New rank crystallizes | Bronze label/state is replaced | Silver emblem and “Silver — Low” resolve sharply | New stage name, number and intensity are readable |
| 9 | Interface settles | No active Bronze fragments remain | Silver Low rests with restrained glow | Base UI returns to normal brightness; no layout jump |

## Suggested motion envelope (provisional)

These are starting points for a motion prototype, not locked timings:
- Total transition: approximately 1.8–2.6 seconds.
- Beats 1–2: short acceleration and convergence.
- Beat 3: brief focus dim.
- Beat 4: one quick pulse.
- Beats 5–7: material exchange, with old and new materials not competing for long.
- Beat 8: short crisp resolve.
- Beat 9: gentle settle.

Tune timing against the source reference and a real prototype. Do not treat these values as final.

## Reduced-motion mode
Replace particle acceleration, shockwave and fragment motion with:
1. brief background dim,
2. crossfade from Bronze material to Silver material,
3. update stage name/intensity,
4. restore background luminance.

Keep all state information available without animation.

## Transition acceptance checks
- [ ] Bronze High is clearly the outgoing state.
- [ ] Silver Low is clearly the incoming state.
- [ ] SAGE blue/black identity is visible throughout.
- [ ] No full-screen bronze or silver color takeover.
- [ ] Emblem center and silhouette stay aligned.
- [ ] No clipping, flicker, illegible labels or sudden layout shift.
- [ ] Reduced-motion alternative is clear and complete.
