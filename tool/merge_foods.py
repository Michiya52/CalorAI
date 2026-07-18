"""Merge CalorAI's four food assets + inline curated list into one clean
myfcd_full.json — the only asset the app reads at runtime.

Run from CalorAI/CalorAI (the Flutter root).
"""
import json
import re
import sys
from collections import Counter

ROOT = 'assets/data'


def load(p):
    return json.load(open(p, encoding='utf-8-sig'))


# ── 1. Extract inline curatedEssentials from seed_data.dart ──────────────
def extract_curated():
    src = open('lib/utils/seed_data.dart', encoding='utf-8').read()
    m = re.search(r'curatedEssentials = \[(.*?)\n  \];', src, re.S)
    if not m:
        sys.exit('curatedEssentials list not found')
    body = '[' + m.group(1) + ']'
    body = re.sub(r'//[^\n"]*\n', '\n', body)          # line comments
    body = re.sub(r',\s*([}\]])', r'\1', body)          # trailing commas
    return json.loads(body)


# ── 2. Name cleaning ─────────────────────────────────────────────────────
ACRONYMS = {'uht': 'UHT', 'abc': 'ABC', 'bbq': 'BBQ', 'rtd': 'RTD',
            'sg': 'SG', 'my': 'MY'}
BRANDS = {'nestle', 'unilever', 'mondelez', 'cadbury', "kellogg's", 'kelloggs',
          "julie's", 'julies', 'milo', 'maggi', 'dutch lady', "munchy's",
          'munchys', 'mamee', 'knorr', 'nescafe', 'f&n', "yeo's", 'yeos',
          'gardenia', 'massimo', 'marigold', 'ayam brand', 'indomie',
          'ovaltine', 'horlicks', 'chipsmore', 'oreo',
          'boh', 'boh plantations', 'campbell', 'kimball', 'eb frozen food',
          'eb', 'msm', 'sweet home', 'chatime', 'tesco', 'adabi', 'hock ju',
          'fuji bakery', 'cap rambutan'}

SMALL_WORDS = {'and', 'or', 'of', 'in', 'with', 'the', 'a', 'an', 'de'}


def title_case(text):
    words = text.split(' ')
    out = []
    for i, w in enumerate(words):
        if not w:
            continue
        lw = w.lower()
        if lw.strip('(),') in ACRONYMS:
            core = ACRONYMS[lw.strip('(),')]
            out.append(re.sub(r'[a-zA-Z]+', core, w, count=1))
        elif i > 0 and lw in SMALL_WORDS:
            out.append(lw)
        else:
            idx = next((j for j, c in enumerate(w) if c.isalpha()), None)
            if idx is None:
                out.append(w)
            else:
                out.append(w[:idx] + w[idx].upper() + w[idx + 1:].lower())
    return ' '.join(out)


def clean_name(name, branded=False):
    n = name.strip().replace('�', '-')
    # scientific names & junk after ';'
    n = n.split(';')[0].strip()
    # trailing separators / stray punctuation
    n = re.sub(r'[\s,;.*]+$', '', n)
    n = re.sub(r'\s{2,}', ' ', n)
    n = re.sub(r'\(\s+', '(', n)
    n = re.sub(r'\s+\)', ')', n)
    # "(Kuih Koci)" -> "Kuih Koci"  (Malay-only names wrapped in parens)
    if n.startswith('(') and n.endswith(')') and n.count('(') == 1:
        n = n[1:-1].strip()
    if branded:
        # "NESTLE, MILO, KOPI SEGERA" -> "Milo Kopi Segera (Nestle)"
        parts = [p.strip() for p in n.split(',') if p.strip()]
        lead_brands = []
        while parts and parts[0].lower() in BRANDS and len(parts) > 1:
            lead_brands.append(parts.pop(0))
        n = ' '.join(parts)
        if lead_brands:
            n = f"{n} ({title_case(lead_brands[0])})"
    else:
        # tidy comma spacing: "Bread , coconut" -> "Bread, Coconut"
        n = re.sub(r'\s*,\s*', ', ', n)
    return title_case(n)


def extract_malay(name_en):
    """Pull '(Pisang Tanduk)' out of 'Banana (Pisang Tanduk)'."""
    m = re.search(r'\(([^)]+)\)', name_en)
    return m.group(1).strip() if m else ''


# ── 3. Category normalization ────────────────────────────────────────────
CAT_GRAINS = 'Grains, Noodles & Starches'
CAT_VEG = 'Vegetables & Legumes'
CAT_FRUIT = 'Fruits'
CAT_NUTS = 'Nuts & Seeds'
CAT_MEAT = 'Meats, Poultry & Seafood'
CAT_DAIRY = 'Dairy & Eggs'
CAT_FATS = 'Fats & Oils'
CAT_BEV = 'Beverages'
CAT_SPICE = 'Spices, Condiments & Sauces'
CAT_SWEET = 'Desserts & Sweets'
CAT_SNACK = 'Snacks'
CAT_DISH = 'Local & Mixed Dishes'
CAT_OTHER = 'Other / Miscellaneous'

CANONICAL = {CAT_GRAINS, CAT_VEG, CAT_FRUIT, CAT_NUTS, CAT_MEAT, CAT_DAIRY,
             CAT_FATS, CAT_BEV, CAT_SPICE, CAT_SWEET, CAT_SNACK, CAT_DISH,
             CAT_OTHER}

MYFCD_1997 = {
    '1': CAT_GRAINS, '2': CAT_NUTS, '3': CAT_VEG, '4': CAT_VEG,
    '5': CAT_FRUIT, '6': CAT_SWEET, '7': CAT_MEAT, '8': CAT_DAIRY,
    '9': CAT_DAIRY, '10': CAT_MEAT, '11': CAT_FATS, '12': CAT_BEV,
    '13': CAT_SPICE, '14': CAT_GRAINS, '23': CAT_SWEET, '24': CAT_SWEET,
    '25': CAT_SWEET, '28': CAT_DISH, '29': CAT_DISH, '30': CAT_DISH,
    '31': CAT_SWEET, '39': CAT_DISH, '44': CAT_DISH, '45': CAT_DISH,
    '46': CAT_DISH, '48': CAT_DISH, '49': CAT_DISH, '50': CAT_DISH,
    '51': CAT_MEAT,
}

MYFCD_INDUSTRY = {
    '1': CAT_GRAINS, '2': CAT_OTHER, '4': CAT_VEG, '5': CAT_FRUIT,
    '6': CAT_SWEET, '7': CAT_MEAT, '9': CAT_DAIRY, '10': CAT_MEAT,
    '12': CAT_BEV, '13': CAT_SPICE, '15': CAT_SWEET, '16': CAT_SWEET,
    '17': CAT_SPICE, '19': CAT_SNACK, '20': CAT_BEV, '21': CAT_SNACK,
}

# MyFCD_Current "Group 1.xx" = raw/packaged foods, "Group 2.x.x" = dishes
MYFCD_CURRENT = {
    '1.01': CAT_GRAINS, '1.02': CAT_SNACK, '1.03': CAT_VEG, '1.04': CAT_SWEET,
    '1.05': CAT_VEG, '1.06': CAT_FRUIT, '1.07': CAT_BEV, '1.08': CAT_MEAT,
    '1.09': CAT_DAIRY, '1.10': CAT_MEAT, '1.11': CAT_DAIRY, '1.12': CAT_FATS,
    '1.13': CAT_BEV, '1.14': CAT_SWEET,
}

CURATED_LABELS = {
    'Noodle Dishes': CAT_DISH, 'Rice Dishes': CAT_DISH,
    'Meat Dishes': CAT_DISH, 'Seafood Dishes': CAT_DISH,
    'Soups': CAT_DISH, 'Breads': CAT_GRAINS, 'Beverages': CAT_BEV,
    'Desserts': CAT_SWEET, 'Snacks': CAT_SNACK,
    # backed_foods.json labels
    'Vegetables': CAT_VEG, 'Fruits': CAT_FRUIT, 'Dairy & Eggs': CAT_DAIRY,
    'Legumes': CAT_VEG, 'Meats': CAT_MEAT, 'Cereals & Grains': CAT_GRAINS,
    'Seafood': CAT_MEAT, 'Nuts & Seeds': CAT_NUTS,
    'Sugars & Sweets': CAT_SWEET, 'Spreads': CAT_SPICE,
    'Fats & Oils': CAT_FATS, 'Condiments': CAT_SPICE,
}

SGFOCOS_TOP = {
    'Beverages': CAT_BEV, 'Grains and staples': CAT_DISH,
    'Meat and alternatives': CAT_DISH,
    'Oils, seasonings and condiments': CAT_SPICE, 'Snacks': CAT_SNACK,
    'Vegetables': CAT_VEG, 'Fruits': CAT_FRUIT, 'Dairy': CAT_DAIRY,
    'Desserts and sweets': CAT_SWEET, 'Soups': CAT_DISH,
    'Mixed dishes': CAT_DISH, 'Dim sum': CAT_DISH, 'Seafood': CAT_DISH,
}


def categorize(item):
    src = item.get('source', '')
    grp = str(item.get('foodGroup', '') or '')
    if grp in CANONICAL:
        return grp
    if grp in CURATED_LABELS:
        return CURATED_LABELS[grp]
    if grp.startswith('Group '):
        num = grp[6:]
        if src == 'MyFCD_1997' and num in MYFCD_1997:
            return MYFCD_1997[num]
        if src == 'MyFCD_Industry' and num in MYFCD_INDUSTRY:
            return MYFCD_INDUSTRY[num]
        if num in MYFCD_CURRENT:
            return MYFCD_CURRENT[num]
        if re.match(r'2\.\d', num):
            # Current dishes: 2.1.x kuih/snacks, 2.2.x cooked, 2.3.x drinks
            if num.startswith('2.1'):
                return CAT_SWEET
            if num.startswith('2.3'):
                return CAT_BEV
            return CAT_DISH
        return CAT_OTHER
    if '>' in grp:  # SGFOCOS hierarchical
        top = grp.split('>')[0].strip()
        sub = grp.split('>')[1].strip().lower()
        if 'dessert' in sub or 'kuih' in sub or 'ice cream' in sub:
            return CAT_SWEET
        return SGFOCOS_TOP.get(top, CAT_DISH)
    return CAT_OTHER


# ── 4. Search terms ──────────────────────────────────────────────────────
def build_search_terms(name_en, name_my):
    terms = set()
    for name in (name_en, name_my):
        low = re.sub(r'[^\w\s-]', ' ', name.lower())
        low = re.sub(r'\s+', ' ', low).strip()
        if low:
            terms.add(low)
            for tok in low.split(' '):
                if len(tok) >= 3:
                    terms.add(tok)
    return sorted(terms)


# ── 5. Sanitize one record ───────────────────────────────────────────────
def sanitize(f, priority):
    raw_en = str(f.get('nameEn', '') or '').strip()
    if not raw_en:
        return None
    branded = f.get('source') == 'MyFCD_Industry'
    name_en = clean_name(raw_en, branded=branded)
    if not name_en:
        return None

    raw_my = str(f.get('nameMy', '') or '').strip()
    if not raw_my or clean_name(raw_my, branded=branded) == name_en:
        raw_my = extract_malay(name_en) or name_en
    name_my = clean_name(raw_my) if raw_my else name_en

    def num(k):
        v = f.get(k)
        return float(v) if isinstance(v, (int, float)) else 0.0

    cal, pro, carb, fat = (num('caloriesPer100g'), num('proteinPer100g'),
                           num('carbsPer100g'), num('fatsPer100g'))
    if cal > 900 or cal < 0 or pro + carb + fat > 102:
        return None

    portions = f.get('portionSizes') or {
        'smallGrams': 100, 'mediumGrams': 250, 'largeGrams': 400}

    return {
        'myfcdCode': str(f.get('myfcdCode') or f.get('foodCode') or ''),
        'nameEn': name_en,
        'nameMy': name_my,
        'nameEnLower': name_en.lower(),
        'nameMyLower': name_my.lower(),
        'searchTerms': build_search_terms(name_en, name_my),
        'foodGroup': categorize(f),
        'caloriesPer100g': cal,
        'proteinPer100g': pro,
        'carbsPer100g': carb,
        'fatsPer100g': fat,
        'sodiumPer100g': num('sodiumPer100g'),
        'sugarPer100g': num('sugarPer100g'),
        'ingredients': f.get('ingredients') or [],
        'portionSizes': portions,
        'source': f.get('source') or 'Curated',
        '_priority': priority,
    }


# ── 5b. New curated additions (common SG/MY foods missing from all sets) ─
def A(en, my, grp, cal, p, c, f, na, su, ing, small, med, large):
    return {'nameEn': en, 'nameMy': my, 'foodGroup': grp,
            'caloriesPer100g': cal, 'proteinPer100g': p, 'carbsPer100g': c,
            'fatsPer100g': f, 'sodiumPer100g': na, 'sugarPer100g': su,
            'ingredients': ing, 'source': 'Curated',
            'portionSizes': {'smallGrams': small, 'mediumGrams': med,
                             'largeGrams': large}}


ADDITIONS = [
    A('Economy Rice (Cai Fan, 1 Meat 2 Veg)', 'Nasi Campur', 'Rice Dishes',
      150, 6.0, 20.0, 5.0, 350, 1.5,
      ['White Rice', 'Meat Dish', 'Vegetable Dishes', 'Gravy'], 350, 500, 650),
    A('Bak Chor Mee (Dry)', 'Mee Daging Cincang', 'Noodle Dishes',
      160, 7.5, 20.0, 5.5, 450, 1.5,
      ['Egg Noodles', 'Minced Pork', 'Pork Slices', 'Liver', 'Mushrooms',
       'Vinegar', 'Chilli'], 300, 400, 500),
    A('Hokkien Prawn Mee (Fried)', 'Mee Hokkien Goreng', 'Noodle Dishes',
      145, 6.0, 17.0, 6.0, 420, 1.0,
      ['Yellow Noodles', 'Rice Vermicelli', 'Prawns', 'Squid', 'Egg',
       'Pork Lard', 'Lime', 'Sambal'], 300, 450, 600),
    A('Lor Mee', 'Lor Mee', 'Noodle Dishes',
      110, 5.0, 15.0, 3.5, 480, 2.0,
      ['Thick Yellow Noodles', 'Starchy Gravy', 'Braised Pork', 'Fish Cake',
       'Egg', 'Vinegar', 'Garlic'], 350, 500, 650),
    A('Braised Duck Rice', 'Nasi Itik', 'Rice Dishes',
      165, 9.0, 19.0, 6.0, 380, 1.0,
      ['White Rice', 'Braised Duck', 'Dark Soy Sauce', 'Cucumber'],
      300, 450, 600),
    A('Chicken Porridge (Congee)', 'Bubur Ayam', 'Rice Dishes',
      55, 3.5, 8.0, 1.0, 250, 0.2,
      ['Rice', 'Chicken Broth', 'Shredded Chicken', 'Ginger',
       'Spring Onions'], 350, 500, 700),
    A('Chwee Kueh', 'Chwee Kueh', 'Snacks',
      155, 2.0, 22.0, 6.5, 480, 1.0,
      ['Steamed Rice Cake', 'Preserved Radish (Chai Poh)', 'Oil', 'Chilli'],
      120, 200, 320),
    A('You Tiao (Fried Dough Fritter)', 'Cakoi', 'Snacks',
      385, 7.0, 45.0, 19.0, 500, 2.0,
      ['Wheat Flour', 'Oil', 'Salt', 'Leavening'], 40, 80, 160),
    A('Tau Huay (Soya Beancurd, Sweet)', 'Tauhu Air', 'Desserts',
      60, 3.0, 9.0, 1.5, 20, 8.0,
      ['Soy Milk', 'Sugar Syrup'], 200, 300, 450),
    A('Roti John', 'Roti John', 'Breads',
      230, 9.0, 24.0, 11.0, 450, 3.0,
      ['Baguette', 'Minced Meat', 'Egg', 'Onion', 'Chilli Sauce',
       'Mayonnaise'], 150, 250, 400),
    A('Sup Kambing (Mutton Soup)', 'Sup Kambing', 'Soups',
      85, 8.0, 3.0, 4.5, 400, 0.5,
      ['Mutton', 'Spiced Broth', 'Fried Shallots', 'Celery'], 300, 450, 600),
    A('Soon Kueh', 'Soon Kueh', 'Snacks',
      150, 3.0, 26.0, 3.5, 350, 1.0,
      ['Rice Flour Skin', 'Turnip', 'Bamboo Shoots', 'Dried Shrimp',
       'Mushrooms'], 100, 180, 280),
    A('Sambal Kangkung', 'Kangkung Belacan', 'Vegetables & Legumes',
      90, 3.0, 7.0, 6.0, 450, 2.5,
      ['Water Spinach', 'Sambal Belacan', 'Garlic', 'Oil'], 100, 180, 300),
    A('Roast Duck (Chinese Style)', 'Itik Panggang', 'Meat Dishes',
      320, 19.0, 1.0, 27.0, 350, 0.0,
      ['Duck', 'Five Spice', 'Soy Sauce', 'Maltose Glaze'], 100, 180, 300),
    A('Half-Boiled Eggs (Kopitiam Style)', 'Telur Separuh Masak',
      'Dairy & Eggs', 145, 12.5, 1.0, 10.0, 180, 0.5,
      ['Eggs', 'Dark Soy Sauce', 'White Pepper'], 55, 110, 165),
    A('Kopi (Coffee with Condensed Milk)', 'Kopi', 'Beverages',
      45, 1.0, 8.0, 1.0, 20, 7.5,
      ['Coffee', 'Condensed Milk'], 180, 250, 350),
    A('Kopi O (Black Coffee with Sugar)', 'Kopi O', 'Beverages',
      25, 0.2, 6.0, 0.0, 5, 6.0, ['Coffee', 'Sugar'], 180, 250, 350),
    A('Teh (Tea with Condensed Milk)', 'Teh', 'Beverages',
      50, 1.2, 9.0, 1.2, 20, 8.0,
      ['Black Tea', 'Condensed Milk'], 180, 250, 350),
    A('Teh O (Black Tea with Sugar)', 'Teh O', 'Beverages',
      20, 0.0, 5.0, 0.0, 3, 5.0, ['Black Tea', 'Sugar'], 180, 250, 350),
    A('Teh C (Tea with Evaporated Milk)', 'Teh C', 'Beverages',
      40, 1.5, 6.5, 1.0, 25, 6.0,
      ['Black Tea', 'Evaporated Milk', 'Sugar'], 180, 250, 350),
    A('Milo Dinosaur', 'Milo Dinosaur', 'Beverages',
      95, 2.0, 16.0, 2.5, 45, 13.0,
      ['Milo Powder', 'Condensed Milk', 'Ice'], 250, 350, 500),
    A('Ang Ku Kueh', 'Kuih Angku', 'Desserts',
      235, 4.0, 48.0, 3.0, 60, 20.0,
      ['Glutinous Rice Flour', 'Mung Bean Paste', 'Sweet Potato'],
      40, 80, 160),
    A('Putu Mayam', 'Putu Mayam', 'Snacks',
      220, 3.5, 42.0, 4.5, 120, 12.0,
      ['Rice Flour Noodles', 'Grated Coconut', 'Orange Sugar'], 80, 150, 250),
    A('Nasi Kerabu', 'Nasi Kerabu', 'Rice Dishes',
      140, 6.0, 20.0, 4.0, 320, 2.0,
      ['Blue Rice', 'Fresh Herbs', 'Salted Egg', 'Fish Crackers',
       'Sambal', 'Grated Coconut'], 300, 450, 600),
    A('Mee Hoon Goreng (Fried Rice Vermicelli)', 'Bihun Goreng',
      'Noodle Dishes', 175, 5.0, 26.0, 6.0, 450, 1.5,
      ['Rice Vermicelli', 'Egg', 'Bean Sprouts', 'Soy Sauce', 'Chilli',
       'Oil'], 250, 350, 500),
    A('Kuih Lapis (Steamed Layer Cake)', 'Kuih Lapis', 'Desserts',
      185, 2.0, 32.0, 5.5, 90, 16.0,
      ['Rice Flour', 'Coconut Milk', 'Sugar', 'Colouring'], 60, 120, 200),
    A('Ikan Bakar (Grilled Fish with Sambal)', 'Ikan Bakar',
      'Seafood Dishes', 165, 20.0, 3.0, 8.0, 420, 1.5,
      ['Fish', 'Sambal', 'Banana Leaf', 'Lime'], 150, 250, 400),
    A('Ayam Masak Merah', 'Ayam Masak Merah', 'Meat Dishes',
      170, 15.0, 7.0, 9.5, 480, 4.5,
      ['Chicken', 'Tomato Sauce', 'Chilli Paste', 'Onion', 'Spices'],
      150, 250, 400),
    A('Cheng Tng', 'Cheng Tng', 'Desserts',
      60, 0.5, 14.5, 0.2, 10, 12.0,
      ['Longan', 'Barley', 'White Fungus', 'Gingko Nuts', 'Rock Sugar Syrup'],
      250, 350, 500),
    A('Vadai', 'Vadai', 'Snacks',
      320, 11.0, 32.0, 16.5, 450, 1.5,
      ['Lentils', 'Spices', 'Curry Leaves', 'Oil'], 50, 100, 180),
]


# ── 6. Merge ─────────────────────────────────────────────────────────────
def norm_key(s):
    return re.sub(r'[^\w\s]', '', s.lower()).strip()


def main():
    sources = [
        (ADDITIONS, 0, 'new additions'),
        (extract_curated(), 0, 'inline curated'),
        (load(f'{ROOT}/backed_my_foods.json'), 1, 'backed_my'),
        (load(f'{ROOT}/backed_foods.json'), 2, 'backed'),
        (load(f'{ROOT}/sgfocos_full.json'), 3, 'sgfocos'),
        (load(f'{ROOT}/myfcd_full.json'), 4, 'myfcd'),
    ]
    merged = {}
    dropped = Counter()
    for items, prio, label in sources:
        kept = 0
        for f in items:
            s = sanitize(f, prio)
            if s is None:
                dropped[label] += 1
                continue
            key = norm_key(s['nameEnLower'])
            if key not in merged or merged[key]['_priority'] > prio:
                merged[key] = s
                kept += 1
        print(f'{label}: {len(items)} in, {kept} kept as winners, '
              f'{dropped[label]} dropped by sanity filters')

    out = sorted(merged.values(), key=lambda x: x['nameEnLower'])
    # Re-issue unique codes where missing/duplicated
    seen = set()
    n = 1
    for item in out:
        item.pop('_priority', None)
        code = item['myfcdCode']
        if not code or code in seen:
            while f'CAL{n:04d}' in seen:
                n += 1
            code = f'CAL{n:04d}'
        item['myfcdCode'] = code
        seen.add(code)

    print('final count:', len(out))
    print('categories:', Counter(x['foodGroup'] for x in out).most_common())
    json.dump(out, open(f'{ROOT}/myfcd_full.json', 'w', encoding='utf-8'),
              ensure_ascii=False, indent=1)
    print('written.')


if __name__ == '__main__':
    main()
