# RectangleFreePro — Workspaces Nommés + Window Rules

## Plan

- [ ] 1. **WorkspaceManager.swift** — Data model + logique switch (déplacer fen. off/on screen à x=-10000)
- [ ] 2. **WindowTracker.swift** — Tracker AXObserver pour détecter destruction de fenêtres, associer nouvelles fen. au workspace actif
- [ ] 3. **WindowAction** — Ajouter switchWorkspace1-9 (108-116) + moveWindowToWorkspace1-9 (117-125)
- [ ] 4. **AppDelegate** — Brancher shortcuts workspaces + indicateur workspace dans menu bar
- [ ] 5. **WindowRule.swift + WindowRulesManager.swift** — Règles auto (AXObserver kAXWindowCreatedNotification + NSWorkspace.didLaunch)
- [ ] 6. **UI** — Section Workspaces + Window Rules dans ProFeaturesViewController
- [ ] 7. **Tests** — WorkspaceManagerTests + WindowRulesManagerTests

## En cours

(rien)

## Complété

(vide au départ)

## Décisions prises

- Workspaces = couche logicielle, fenêtres inactives à x=-10000 (comme AeroSpace)
- Pas de tiling automatique (hors scope)
- Pas de modes modaux (hors scope)
- Détection nouvelles fenêtres = AXObserver kAXWindowCreatedNotification par app
- Persistance via JSONDefault<[WorkspaceConfig]>
