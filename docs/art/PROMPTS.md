# 🎨 الاتجاه الفني الجديد وبرومتات Nano Banana

## الفكرة: «حكاية سماء مضيئة»
- **رسم يدوي فاخر** بروح Ori و Child of Light: ضربات فرشاة ناعمة، وإضاءة على الحواف، وعمق وضباب، وتفاصيل تتوهج.
- **هوية خاصة بنا:** سفن من الخشب والنحاس بزخارف عربية (أرابيسك، وفوانيس معلّقة، ونقوش نحاسية)، وجزر عائمة.
- **البحّارة:** بدل الشخصيات الطفولية، **بحّارة سماء بعباءات وأغطية رأس** وعيون مضيئة، على طريقة لعبة Journey. شكلهم غامض وأنيق، ويُعرفون من بعيد حتى وهم صغار على الشاشة. لون العباءة هو لون اللاعب، ويتغير بالكود.
- **لا** كرتون طفولي، ولا خطوط سوداء سميكة، ولا رسم مسطّح.

---

## 🔁 طريقة العمل (مهمة جدًا)
1. **المرجع:** اخترنا النسخة الأولى من المشهد المرجعي، وهي محفوظة في `docs/art/style_key.jpg`. **أرفقها مع كل برومت**، فهي التي تجعل كل الرسومات بأسلوب واحد. مع برومت البحّار أرفق أيضًا `docs/art/style_key_characters.jpg`، لأن أجسام الشخصيات فيها أوضح.
2. **الخلفية:** Nano Banana لا يعطي صورًا شفافة، لذلك كل برومت يطلب **خلفية خضراء صافية** (أو **بنفسجية** للنباتات الخضراء). أنا أزيلها بعد ذلك.
3. **القوالب:** بعض البرومتات تحتاج إرفاق قالب من `docs/art/templates/`، حتى تطابق الرسمة أماكن الطوابق في اللعبة.
4. **احفظ النتائج** في مجلد `art_inbox/` داخل المشروع بالأسماء المكتوبة هنا، ثم قل لي «وضعت الصور». أنا أزيل الخلفية، وأقص الصور وأصغّرها، وأضع الأجزاء في هيكل حركة، وأدخلها في اللعبة.
5. اطلب **أعلى دقة متاحة** (2K إن توفرت). إذا خرجت صورة بأسلوب مختلف عن المرجع، أعد توليدها ولا تقبلها.

---

## 🧩 كتلتان تُلصقان في أول كل برومت

**كتلة الأسلوب (STYLE)** — ألصقها في كل البرومتات:
```
STYLE: premium hand-painted 2D fantasy game art in the spirit of "Ori and the Will of the Wisps" and "Child of Light": soft painterly brushwork, luminous rim light, rich atmospheric depth, subtle painted texture, glowing accents, elegant readable silhouettes, refined shapes, cinematic warm/cool colour contrast. NOT cartoonish, NOT chibi, NOT flat vector, NO thick black outlines. World: floating sky islands and wooden airships with brass fittings and Arabian craftsmanship (arabesque carvings, brass filigree, pierced-metal lanterns). Key light from the upper left, warm; cool sky-blue bounce light from below. Match the art style of the attached reference image exactly.
```

**كتلة التنسيق (FORMAT)** — للصور التي تصير sprites (كل شيء ما عدا 00 وطبقات السماء):
```
FORMAT: game sprite. Strict side view (orthographic, no perspective), facing RIGHT, centred with generous empty margin, the whole object inside the frame, isolated on a flat solid pure green #00FF00 background: no gradient, no cast shadow, no floor, no scenery, no text, no letters, no watermark, no border.
```
> للنباتات والأشجار (لأنها خضراء): استبدل `pure green #00FF00` بـ `pure magenta #FF00FF`.

---

## الدفعة 1: الأساس (ابدأ بها)

### 00 — المشهد المرجعي ← `style_key.png` (16:9، بدون كتلة FORMAT)
```
[STYLE]
Key art for a cooperative sky-sailing game. A graceful wooden airship with a large patterned fabric balloon (deep crimson and cream panels with gold trim) glides between floating islands at golden hour. Four small hooded sky-sailors in flowing cloaks (teal, crimson, amber, violet) with softly glowing eyes work on deck: one at the ship's wheel, one at a brass cannon, one carrying glowing coal to a furnace. Brass lanterns glow on the ship. Around them: towering sunlit clouds, a sea of clouds far below, distant floating islands with waterfalls and pink blossom trees, crystals glowing under the islands, god rays, drifting motes of light. Side-on camera like a 2D platformer, the ship in the middle third. Cinematic, magical, premium indie game.
```

### 01 — السفينة ← `ship.png` (16:9) — **أرفق** `templates/ship_layout.png` و `style_key.jpg`
```
[STYLE]
[FORMAT]
Paint the player's airship EXACTLY on the attached layout sketch (the first attached image): same size, same position and proportions for the round balloon, brass collar, mast, crow's nest platform, quarterdeck, stern castle, main deck line, railing, crate, hull and bowsprit. The ship faces RIGHT. The blue bars are wooden surfaces the crew walks on: their top edges must stay perfectly flat and at the same height as in the sketch. Ship design, matching the airship in the second attached image: warm honey-brown wooden hull with visible planks, ornate gold arabesque carvings and brass trim, a raised stern castle under the quarterdeck with glowing arched lattice windows, a wooden railing with turned balusters, a long bowsprit, pierced-brass lanterns hanging from the hull and under the crow's nest, rope rigging up to a large round hot-air balloon with crimson and cream panels covered in gold Arabian arabesque patterns, gold seams and a brass collar where it meets the mast. IMPORTANT: leave the areas inside the orange boxes EMPTY deck (no furnace, no ship's wheel, no cannons, no coal, no propeller, no people) — those are separate sprites. Do not paint any labels, lines or boxes from the sketch.
```

### 02 — البحّار (أجزاء مفصولة للحركة) ← `sailor_parts.png` (16:9) — **أرفق** `templates/sailor_parts_layout.png` و `style_key.jpg` و `style_key_characters.jpg`
```
[STYLE]
[FORMAT]
Character cut-out sheet for 2D skeletal animation of ONE small hooded sky-sailor, placed into the labelled boxes of the attached layout (do not paint the labels or boxes). Character: slender, mysterious, about 3 heads tall, a deep hood casting shadow over the face with two softly glowing white eyes, a long flowing scarf, a knee-length cloak over simple trousers, soft leather boots, thin brass buckles. The cloak, hood, sleeves and scarf must be painted in NEUTRAL LIGHT GREY / OFF-WHITE fabric only (no other colour on the fabric) — the game will tint them to each player's colour. Boots and buckles keep their own dark leather and brass colours. Parts (all facing right, same scale, not overlapping, each fully visible, with a little extra material at the joints): 1 head with hood, 2 torso with the cloak body, 3 the scarf tail flowing backwards, 4 front arm with hand, 5 back arm with hand, 6 front leg with boot, 7 back leg with boot, 8 in the wide bottom box: the whole character assembled in a walking pose for reference.
```

### 03 — طائر العاصفة (جسم وجناح منفصلان) ← `storm_bird.png` (1:1)
```
[STYLE]
[FORMAT]
Enemy sprite sheet: a menacing "storm crow" — a sleek dark indigo bird with storm-grey feathers, electric cyan glowing eyes and faint crackling light on its feather tips, sharp amber beak, aggressive shape. Three separate pieces side by side with big gaps, all facing right, same scale: (1) the body with head and tail but WITHOUT wings, (2) one wing alone, spread wide, painted so it can rotate at the shoulder, (3) the full bird diving downward, wings swept back (reference pose).
```

### 04 — الصخور العائمة ← `boulders.png` (16:9)
```
[STYLE]
[FORMAT]
Three different floating sky boulders in one row with big gaps between them: rough grey-violet stone, weathered and cracked, with veins of glowing cyan crystal running through them and small crystal clusters growing out of the top, a few tiny roots hanging underneath. Rounded, chunky silhouettes (each roughly as wide as tall), no ground, no shadow.
```

---

## الدفعة 2: بقية الرحلة

### 05 — سفينة القراصنة ← `pirate_ship.png` (16:9) — **أرفق** `ship_layout.png` و `style_key.jpg`
```
[STYLE]
[FORMAT]
Paint the sky pirates' flagship on the attached layout sketch (same proportions, but facing LEFT — mirror the layout horizontally). Dark stained purple-black wood, tarnished bronze trim with sharp spikes, a torn round dark violet balloon with patched panels and a yellow lightning emblem, tattered pennants, glowing sickly-yellow lanterns and portholes, menacing carved figurehead. Leave the deck empty (no crew). No labels or boxes.
```

### 06 — المروحة ← `propeller.png` (1:1)
```
[STYLE]
[FORMAT]
A ship's propeller seen from the side for a spinning animation: a brass hub with two long carved wooden blades, painted pointing straight up and down, flat side-on view. Plus, separately to the right, the same propeller as a soft motion-blurred disc (fast spin).
```

### 07 — المدفع ← `cannon.png` (16:9)
```
[STYLE]
[FORMAT]
A deck cannon in two separate pieces with a big gap: (1) the wooden carriage with two spoked wheels and brass fittings, no barrel; (2) the barrel alone, horizontal, pointing right: dark bronze with engraved arabesque bands and a flared muzzle, its pivot point at the middle.
```

### 08 — الدفة ← `helm.png` (1:1)
```
[STYLE]
[FORMAT]
A ship's wheel in two separate pieces: (1) the wooden stand/pedestal with brass bands; (2) the wheel alone seen exactly face-on (a perfect circle, eight spokes with turned handles, brass hub), so it can spin in the game.
```

### 09 — المحرك والفحم والصندوق ← `engine_props.png` (16:9)
```
[STYLE]
[FORMAT]
Four separate props in a row with big gaps: (1) a brick-and-brass ship furnace with a round iron door opening that shows a dark empty firebox (no flames painted), a tall thin chimney pipe on its left side; (2) a wooden bin heaped with shiny black coal lumps; (3) a sturdy wooden cargo crate with iron corners; (4) a round black pirate bomb with a short fuse, and next to it a small iron cannonball.
```

### 10 — السماء (طبقات منفصلة للعمق)
- **10a** ← `sky_far.png` (16:9)، بدون كتلة FORMAT:
```
[STYLE]
Background painting only, for the farthest parallax layer of a side-scrolling game: a vast luminous sky gradient from deep blue at the top to warm peach near the horizon, a soft sun glow in the upper right, very faint far-away cloud banks and tiny hazy floating islands near the horizon. No foreground, no characters, no ships. Must tile seamlessly left to right.
```
- **10b** ← `clouds_mid.png` (16:9):
```
[STYLE]
[FORMAT]
Six separate large fluffy cumulus clouds of different shapes, sunlit from the upper left with warm highlights and cool blue-violet shadows, soft painterly edges, isolated on the green background with gaps between them.
```
- **10c** ← `cloud_sea.png` (16:9)، بدون كتلة FORMAT:
```
[STYLE]
A wide band of billowing cloud sea seen from the side, bright tops lit by the sun, fading into soft haze at the bottom, painted on a flat solid pure green #00FF00 sky above it. Must tile seamlessly left to right. No islands, no ships.
```
- **10d** ← `far_islands.png` (16:9):
```
[STYLE]
[FORMAT]
Five small distant floating islands of different shapes, seen from the side through atmospheric haze (desaturated blue-violet, low contrast): rocky undersides tapering to a point, a little greenery and one tiny waterfall on top.
```

---

## الدفعة 3: الجزر

### 11 — أرض الجزيرة ← `island_ground.png` (16:9) — خلفية بنفسجية
```
[STYLE]
[FORMAT with magenta]
Tileable terrain pieces for a floating-island platformer, separated by big gaps: (1) a long horizontal strip of grass-topped ledge edge (lush grass with small flowers, a lip of soil), must tile seamlessly left-right; (2) a square block of the soil-and-rock body texture that tiles seamlessly in all directions; (3) the rocky underside of an island tapering to a point with hanging roots and glowing cyan crystals; (4) a left end-cap and (5) a right end-cap of the grassy ledge.
```

### 12 — الأشجار ← `trees.png` (16:9) — خلفية بنفسجية
```
[STYLE]
[FORMAT with magenta]
Three separate trees in a row, standing on nothing: (1) a graceful pink blossom tree (like a cherry tree) with soft glowing petals, (2) a lush round green tree, (3) a lavender-violet blossom tree. Elegant twisting trunks, painterly foliage lit from the upper left.
```

### 13 — نباتات صغيرة ← `plants.png` (16:9) — خلفية بنفسجية
```
[STYLE]
[FORMAT with magenta]
A sheet of small plants with big gaps: three round bushes, three grass tufts, four small flower clumps (pink, gold, white, blue), two ferns, one patch of glowing mushrooms.
```

### 14 — قطع الألغاز ← `puzzle_props.png` (16:9)
```
[STYLE]
[FORMAT]
A sheet of separate puzzle props with big gaps, all at the same scale: (1) a floor lever: stone base plus a separate brass handle with a round knob; (2) a round pressure plate set in a stone rim; (3) a gate: two carved stone pillars with an arch top, and separately the wooden portcullis with iron bands; (4) a bronze bell hanging under a small wooden frame with a roof, and the bell alone; (5) a treasure chest closed, and separately its lid; (6) a floating wooden lift platform; (7) a brass crank wheel on a post; (8) a round metal wind-vent grate set in the ground; (9) a blank wooden signboard on two posts (no writing); (10) a glowing cyan crystal gem; (11) a torn piece of an old parchment sky-map.
```

---

## ملاحظات لي (Claude) عند إدخال الصور
- قالب السفينة: `img = game + (175, 200)` على لوحة 1600×900 (قمة البالون عند y=-180 في اللعبة، أعلى الشاشة). البالون الجديد دائري، أي أن `Ship.paint()` والإطار القديم يتغيران. أقيس خط السطح (y=520 في اللعبة) في الصورة الناتجة لأضبط المقياس والإزاحة بدقة.
- البحّار: أجزاء العباءة رمادية، وأصبغها بلون اللاعب في الكود (modulate) على طبقة العباءة فقط.
- الطائر: الجناح يدور حول الكتف في الكود لصنع الرفرفة.
- أزيل الخلفية الخضراء أو البنفسجية بـ chroma key مع تنعيم الحواف، ثم أقص الصور وأصغّرها وأسجّلها في `assets/art/CREDITS.md`.
