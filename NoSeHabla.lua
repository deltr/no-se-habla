-- No Se Habla
-- Filters non-Latin-script chat in public channels into clickable stubs.
-- Hover the link to peek; click to commit the original to chat history.

local ADDON_NAME = "No Se Habla"
local STUB_TEXT = "|cffff7f50[suppressed]|r"  -- tomato color so it reads as clickable
local LINK_PREFIX = "nsh:"
local CACHE_SIZE = 200
local DEFAULT_THRESHOLD = 30  -- percent of letters that must be non-Latin

local CHANNEL_EVENTS = {
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_EMOTE",
    "CHAT_MSG_CHANNEL",
}

-- Distinctive transliterated Russian words. Hits are counted against this set
-- AFTER the script-based check fails. Two or more hits in one message flag it.
-- Words must be very rare/impossible in English. Length >= 3.
local TRANSLIT_RUSSIAN = {
    -- function words
    ["dlya"]=1, ["vseh"]=1, ["vsem"]=1, ["vsego"]=1, ["vse"]=1,
    ["chto"]=1, ["chego"]=1, ["chemu"]=1,
    ["kogda"]=1, ["togda"]=1, ["pochemu"]=1, ["zachem"]=1,
    ["etogo"]=1, ["etot"]=1, ["etoy"]=1, ["etu"]=1, ["eti"]=1, ["eta"]=1, ["eto"]=1,
    ["seichas"]=1, ["seychas"]=1, ["sichas"]=1,
    ["bolshe"]=1, ["menshe"]=1, ["tolko"]=1, ["uzhe"]=1, ["esche"]=1, ["eshche"]=1,
    ["mozhno"]=1, ["nuzhno"]=1, ["nado"]=1, ["nelzya"]=1,
    ["prosto"]=1, ["ochen"]=1, ["pochti"]=1, ["mnogo"]=1, ["nemnogo"]=1, ["malo"]=1,
    -- pronouns
    ["menya"]=1, ["tebya"]=1, ["nego"]=1, ["nih"]=1,
    ["nashih"]=1, ["vashih"]=1, ["nashego"]=1, ["vashego"]=1, ["nashe"]=1, ["nashi"]=1,
    ["mnoy"]=1, ["toboy"]=1, ["soboi"]=1,
    -- common verbs
    ["delat"]=1, ["delaet"]=1, ["delayu"]=1, ["sdelat"]=1, ["sdelaem"]=1,
    ["smotret"]=1, ["smotri"]=1,
    ["znayu"]=1, ["znaet"]=1, ["znaem"]=1, ["znat"]=1,
    ["khochu"]=1, ["hochu"]=1, ["khochesh"]=1, ["hochesh"]=1, ["khochet"]=1, ["hochet"]=1,
    ["budet"]=1, ["budu"]=1, ["budem"]=1, ["budesh"]=1,
    ["dumayu"]=1, ["dumaesh"]=1, ["dumaet"]=1,
    ["jdem"]=1, ["zhdem"]=1, ["jdu"]=1, ["zhdu"]=1, ["jdat"]=1, ["zhdat"]=1,
    ["idem"]=1, ["idti"]=1, ["idu"]=1, ["poshli"]=1, ["poshel"]=1,
    ["pomogi"]=1, ["pomoch"]=1, ["pomogite"]=1, ["pomogu"]=1,
    ["skazhi"]=1, ["skazat"]=1, ["skazal"]=1,
    ["mogu"]=1, ["mozhet"]=1, ["mozhem"]=1,
    ["nashel"]=1, ["nashla"]=1, ["nashli"]=1,
    ["dayut"]=1, ["dayte"]=1,
    ["pridem"]=1, ["pridet"]=1, ["prishel"]=1,
    ["napishi"]=1, ["napishite"]=1, ["pishi"]=1, ["pishet"]=1, ["pishu"]=1,
    -- game / social / trade
    ["nabor"]=1, ["nabira"]=1, ["nabiraem"]=1,
    ["aktivnyh"]=1, ["aktivny"]=1, ["aktivnye"]=1, ["aktiv"]=1,
    ["igrokov"]=1, ["igroki"]=1, ["igroka"]=1, ["igroku"]=1,
    ["igra"]=1, ["igry"]=1, ["igre"]=1, ["igroy"]=1, ["igrat"]=1, ["igraem"]=1,
    ["gildiya"]=1, ["gildii"]=1, ["gildiyu"]=1, ["gildiey"]=1,
    ["klan"]=1, ["klane"]=1, ["klana"]=1, ["klanom"]=1,
    ["sovmestnoi"]=1, ["sovmestno"]=1, ["sovmestnaya"]=1, ["sovmestnyh"]=1,
    ["kacha"]=1, ["kachat"]=1, ["prokach"]=1, ["pokach"]=1, ["pokachat"]=1,
    ["prodam"]=1, ["prodayu"]=1, ["prodaem"]=1, ["prodazha"]=1,
    ["kuplyu"]=1, ["kuplu"]=1, ["pokupayu"]=1, ["pokupaem"]=1,
    ["obmen"]=1, ["menyayu"]=1, ["menyaem"]=1,
    ["tsena"]=1, ["cena"]=1, ["skolko"]=1, ["deshevle"]=1, ["dorozhe"]=1,
    ["ishchem"]=1, ["ischem"]=1, ["ischu"]=1, ["ishchu"]=1,
    ["trebuyutsya"]=1, ["trebuetsya"]=1,
    ["reidy"]=1, ["rejdy"]=1, ["podzemelya"]=1, ["podzem"]=1,
    -- greetings / exclamations
    ["priv"]=1, ["privet"]=1, ["privetiki"]=1, ["zdrav"]=1, ["zdravstvuyte"]=1,
    ["spasibo"]=1, ["spasiba"]=1, ["pasiba"]=1, ["spasib"]=1,
    ["pozhaluysta"]=1, ["pojaluysta"]=1,
    ["izvinite"]=1, ["izvini"]=1,
    ["poka"]=1, ["dosvidaniya"]=1,
    -- demonstratives / locative
    ["zdes"]=1, ["tut"]=1, ["tam"]=1, ["kuda"]=1, ["otkuda"]=1,
    -- adjectives common
    ["khorosho"]=1, ["horosho"]=1, ["ploho"]=1, ["normalno"]=1,
    ["bolshoi"]=1, ["bolshoy"]=1, ["malenkiy"]=1, ["malenky"]=1,
    ["luchshe"]=1, ["huzhe"]=1, ["khuzhe"]=1, ["lutshe"]=1,
    ["krasivo"]=1, ["krasivyy"]=1, ["plohoy"]=1, ["plohoye"]=1,
    -- relations
    ["drug"]=1, ["druga"]=1, ["druzhba"]=1, ["druzya"]=1, ["druzey"]=1,
    ["bratan"]=1, ["bratishka"]=1, ["sestra"]=1, ["sestrenka"]=1,
    ["rebyata"]=1, ["parni"]=1, ["devushki"]=1, ["lyudi"]=1, ["chuvak"]=1,
    -- time
    ["dnem"]=1, ["nochyu"]=1, ["utrom"]=1, ["vecherom"]=1,
    ["segodnya"]=1, ["zavtra"]=1, ["vchera"]=1,
    -- misc
    ["pomosch"]=1, ["pomoshch"]=1, ["zaschita"]=1, ["zashita"]=1,
    ["nuzhna"]=1, ["nuzhen"]=1,
    -- nationality / context
    ["russkiy"]=1, ["russkie"]=1, ["russkih"]=1,
    ["ukrainets"]=1, ["belorus"]=1,
}

local TRANSLIT_MIN_HITS = 2  -- min wordlist hits before flagging

----------------------------------------------------------------------
-- SavedVariables
----------------------------------------------------------------------

local DB  -- bound on ADDON_LOADED

local function defaults()
    return {
        enabled = true,
        threshold = DEFAULT_THRESHOLD,
    }
end

----------------------------------------------------------------------
-- Detector
----------------------------------------------------------------------

-- Decode one UTF-8 codepoint starting at byte i.
-- Returns (codepoint, next_index). codepoint is -1 on malformed.
local function decode_utf8(s, i)
    local b1 = string.byte(s, i)
    if not b1 then return nil, i end
    if b1 < 0x80 then
        return b1, i + 1
    elseif b1 < 0xC0 then
        return -1, i + 1  -- stray continuation
    elseif b1 < 0xE0 then
        local b2 = string.byte(s, i + 1) or 0
        return (b1 - 0xC0) * 64 + (b2 - 0x80), i + 2
    elseif b1 < 0xF0 then
        local b2 = string.byte(s, i + 1) or 0
        local b3 = string.byte(s, i + 2) or 0
        return (b1 - 0xE0) * 4096 + (b2 - 0x80) * 64 + (b3 - 0x80), i + 3
    else
        local b2 = string.byte(s, i + 1) or 0
        local b3 = string.byte(s, i + 2) or 0
        local b4 = string.byte(s, i + 3) or 0
        return (b1 - 0xF0) * 262144 + (b2 - 0x80) * 4096
             + (b3 - 0x80) * 64 + (b4 - 0x80), i + 4
    end
end

-- Strip Blizzard color escapes, chat hyperlinks, and texture escapes. Note we
-- remove hyperlinks ENTIRELY (display text and all): "[Quest Name]" inside a
-- |H...|h...|h is game content, not language. Counting "Wildhammer Bones" as
-- foreign tokens caused a false positive on English LFM messages that linked
-- quests. The cache still stores the original (un-stripped) message intact.
local function strip_escapes(text)
    text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    text = string.gsub(text, "|r", "")
    text = string.gsub(text, "|H.-|h.-|h", "")
    text = string.gsub(text, "|T.-|t", "")
    return text
end

-- Map UTF-8 accented Latin characters to ASCII so the dictionary lookup
-- catches both "también" and "tambien". Covers Latin-1 Supplement (Romance,
-- German), Latin Extended-A (Polish, Czech, Slovak, Hungarian, Croatian,
-- Romanian, Turkish, Baltic), and a few Latin Extended-B for Romanian.
local ACCENT_MAP = {
    -- 0xC3 prefix: Latin-1 Supplement (Romance + German)
    -- lowercase
    ["\195\160"]="a", ["\195\161"]="a", ["\195\162"]="a", ["\195\163"]="a", ["\195\164"]="a", ["\195\165"]="a",
    ["\195\168"]="e", ["\195\169"]="e", ["\195\170"]="e", ["\195\171"]="e",
    ["\195\172"]="i", ["\195\173"]="i", ["\195\174"]="i", ["\195\175"]="i",
    ["\195\178"]="o", ["\195\179"]="o", ["\195\180"]="o", ["\195\181"]="o", ["\195\182"]="o",
    ["\195\185"]="u", ["\195\186"]="u", ["\195\187"]="u", ["\195\188"]="u",
    ["\195\177"]="n", ["\195\167"]="c", ["\195\189"]="y", ["\195\191"]="y",
    -- uppercase
    ["\195\128"]="A", ["\195\129"]="A", ["\195\130"]="A", ["\195\131"]="A", ["\195\132"]="A", ["\195\133"]="A",
    ["\195\136"]="E", ["\195\137"]="E", ["\195\138"]="E", ["\195\139"]="E",
    ["\195\140"]="I", ["\195\141"]="I", ["\195\142"]="I", ["\195\143"]="I",
    ["\195\146"]="O", ["\195\147"]="O", ["\195\148"]="O", ["\195\149"]="O", ["\195\150"]="O",
    ["\195\153"]="U", ["\195\154"]="U", ["\195\155"]="U", ["\195\156"]="U",
    ["\195\145"]="N", ["\195\135"]="C", ["\195\157"]="Y",
    -- 0xC4 prefix: Latin Extended-A (first half)
    ["\196\128"]="A", ["\196\129"]="a",  -- Ā ā
    ["\196\130"]="A", ["\196\131"]="a",  -- Ă ă (Romanian)
    ["\196\132"]="A", ["\196\133"]="a",  -- Ą ą (Polish)
    ["\196\134"]="C", ["\196\135"]="c",  -- Ć ć (Polish)
    ["\196\136"]="C", ["\196\137"]="c",  -- Ĉ ĉ
    ["\196\138"]="C", ["\196\139"]="c",  -- Ċ ċ
    ["\196\140"]="C", ["\196\141"]="c",  -- Č č (Czech/Slovak)
    ["\196\142"]="D", ["\196\143"]="d",  -- Ď ď (Czech)
    ["\196\144"]="D", ["\196\145"]="d",  -- Đ đ (Croatian)
    ["\196\146"]="E", ["\196\147"]="e",  -- Ē ē
    ["\196\148"]="E", ["\196\149"]="e",  -- Ĕ ĕ
    ["\196\150"]="E", ["\196\151"]="e",  -- Ė ė
    ["\196\152"]="E", ["\196\153"]="e",  -- Ę ę (Polish)
    ["\196\154"]="E", ["\196\155"]="e",  -- Ě ě (Czech)
    ["\196\158"]="G", ["\196\159"]="g",  -- Ğ ğ (Turkish)
    ["\196\168"]="I", ["\196\169"]="i",  -- Ĩ ĩ
    ["\196\170"]="I", ["\196\171"]="i",  -- Ī ī
    ["\196\172"]="I", ["\196\173"]="i",  -- Ĭ ĭ
    ["\196\174"]="I", ["\196\175"]="i",  -- Į į (Lithuanian)
    ["\196\176"]="I", ["\196\177"]="i",  -- İ ı (Turkish)
    ["\196\182"]="K", ["\196\183"]="k",  -- Ķ ķ (Latvian)
    ["\196\185"]="L", ["\196\186"]="l",  -- Ĺ ĺ
    ["\196\187"]="L", ["\196\188"]="l",  -- Ļ ļ (Latvian)
    ["\196\189"]="L", ["\196\190"]="l",  -- Ľ ľ (Slovak)
    -- 0xC5 prefix: Latin Extended-A (second half)
    ["\197\129"]="L", ["\197\130"]="l",  -- Ł ł (Polish)
    ["\197\131"]="N", ["\197\132"]="n",  -- Ń ń (Polish)
    ["\197\133"]="N", ["\197\134"]="n",  -- Ņ ņ (Latvian)
    ["\197\135"]="N", ["\197\136"]="n",  -- Ň ň (Czech)
    ["\197\140"]="O", ["\197\141"]="o",  -- Ō ō
    ["\197\142"]="O", ["\197\143"]="o",  -- Ŏ ŏ
    ["\197\144"]="O", ["\197\145"]="o",  -- Ő ő (Hungarian)
    ["\197\148"]="R", ["\197\149"]="r",  -- Ŕ ŕ
    ["\197\150"]="R", ["\197\151"]="r",  -- Ŗ ŗ
    ["\197\152"]="R", ["\197\153"]="r",  -- Ř ř (Czech)
    ["\197\154"]="S", ["\197\155"]="s",  -- Ś ś (Polish)
    ["\197\156"]="S", ["\197\157"]="s",  -- Ŝ ŝ
    ["\197\158"]="S", ["\197\159"]="s",  -- Ş ş (Turkish/Romanian)
    ["\197\160"]="S", ["\197\161"]="s",  -- Š š (Czech)
    ["\197\162"]="T", ["\197\163"]="t",  -- Ţ ţ (Romanian alt)
    ["\197\164"]="T", ["\197\165"]="t",  -- Ť ť (Czech)
    ["\197\168"]="U", ["\197\169"]="u",  -- Ũ ũ
    ["\197\170"]="U", ["\197\171"]="u",  -- Ū ū (Latvian)
    ["\197\172"]="U", ["\197\173"]="u",  -- Ŭ ŭ
    ["\197\174"]="U", ["\197\175"]="u",  -- Ů ů (Czech)
    ["\197\176"]="U", ["\197\177"]="u",  -- Ű ű (Hungarian)
    ["\197\178"]="U", ["\197\179"]="u",  -- Ų ų (Lithuanian)
    ["\197\180"]="W", ["\197\181"]="w",
    ["\197\182"]="Y", ["\197\183"]="y",
    ["\197\184"]="Y",
    ["\197\185"]="Z", ["\197\186"]="z",  -- Ź ź (Polish)
    ["\197\187"]="Z", ["\197\188"]="z",  -- Ż ż (Polish)
    ["\197\189"]="Z", ["\197\190"]="z",  -- Ž ž (Czech/Slovak)
    -- 0xC8 prefix: Latin Extended-B (Romanian comma-below s/t)
    ["\200\152"]="S", ["\200\153"]="s",  -- Ș ș
    ["\200\154"]="T", ["\200\155"]="t",  -- Ț ț
}

local function strip_accents(text)
    text = string.gsub(text, "\195[\128-\191]", function(c) return ACCENT_MAP[c] or c end)
    text = string.gsub(text, "\196[\128-\191]", function(c) return ACCENT_MAP[c] or c end)
    text = string.gsub(text, "\197[\128-\191]", function(c) return ACCENT_MAP[c] or c end)
    text = string.gsub(text, "\200[\128-\191]", function(c) return ACCENT_MAP[c] or c end)
    return text
end

-- Lowercase + accent-strip + escape-strip, so dictionary keys can be plain ASCII.
local function normalize_for_dict(text)
    text = strip_escapes(text)
    text = strip_accents(text)
    return string.lower(text)
end

local function count_dict_hits(text, dict, max_needed)
    local normalized = normalize_for_dict(text)
    local hits = 0
    for word in string.gmatch(normalized, "[%a]+") do
        if dict[word] then
            hits = hits + 1
            if hits >= max_needed then return hits end
        end
    end
    return hits
end

-- Is this codepoint a "Latin-script" letter (or close enough that we don't filter)?
local function is_latin_codepoint(cp)
    if cp < 0 then return false end
    if cp < 0x80 then return true end                -- Basic Latin
    if cp <= 0x024F then return true end             -- Latin-1 Sup, Latin Ext-A, Ext-B
    if cp <= 0x02FF then return true end             -- IPA Extensions, Spacing Modifiers
    if cp <= 0x036F then return true end             -- Combining Diacriticals
    return false
end

-- Is this codepoint a letter we should count?
-- We only count letters in scripts we recognize; everything else (digits, punctuation,
-- symbols, emoji) is skipped so they don't affect the ratio either way.
local function is_letter_codepoint(cp)
    if cp < 0 then return false end
    -- Latin letters
    if cp >= 0x41 and cp <= 0x5A then return true end          -- A-Z
    if cp >= 0x61 and cp <= 0x7A then return true end          -- a-z
    if cp >= 0xC0 and cp <= 0x024F then return true end        -- Latin-1 Sup + Ext-A/B
    -- Non-Latin scripts we consider foreign
    if cp >= 0x0370 and cp <= 0x03FF then return true end      -- Greek
    if cp >= 0x0400 and cp <= 0x04FF then return true end      -- Cyrillic
    if cp >= 0x0500 and cp <= 0x052F then return true end      -- Cyrillic Sup
    if cp >= 0x0530 and cp <= 0x058F then return true end      -- Armenian
    if cp >= 0x0590 and cp <= 0x05FF then return true end      -- Hebrew
    if cp >= 0x0600 and cp <= 0x06FF then return true end      -- Arabic
    if cp >= 0x0700 and cp <= 0x074F then return true end      -- Syriac
    if cp >= 0x0900 and cp <= 0x097F then return true end      -- Devanagari
    if cp >= 0x0E00 and cp <= 0x0E7F then return true end      -- Thai
    if cp >= 0x1100 and cp <= 0x11FF then return true end      -- Hangul Jamo
    if cp >= 0x3040 and cp <= 0x309F then return true end      -- Hiragana
    if cp >= 0x30A0 and cp <= 0x30FF then return true end      -- Katakana
    if cp >= 0x3400 and cp <= 0x4DBF then return true end      -- CJK Ext A
    if cp >= 0x4E00 and cp <= 0x9FFF then return true end      -- CJK Unified
    if cp >= 0xAC00 and cp <= 0xD7AF then return true end      -- Hangul Syllables
    if cp >= 0xFF66 and cp <= 0xFF9F then return true end      -- Halfwidth Katakana
    return false
end

local function is_likely_foreign(text, threshold)
    if not text or text == "" then return false end
    text = strip_escapes(text)
    local total, foreign = 0, 0
    local i, n = 1, #text
    while i <= n do
        local cp, ni = decode_utf8(text, i)
        i = ni
        if cp and is_letter_codepoint(cp) then
            total = total + 1
            if not is_latin_codepoint(cp) then
                foreign = foreign + 1
            end
        end
    end
    if total == 0 then return false end
    return (foreign * 100 / total) >= threshold
end

-- Detect transliterated Russian (Latin chars, Russian words). Counts hits
-- against the TRANSLIT_RUSSIAN set; returns true at TRANSLIT_MIN_HITS or more.
local function is_transliterated_russian(text)
    if not text or text == "" then return false end
    return count_dict_hits(text, TRANSLIT_RUSSIAN, TRANSLIT_MIN_HITS) >= TRANSLIT_MIN_HITS
end

-- Distinctive English function words / pronouns / auxiliaries. Used by the
-- English-density check below. Words that overlap with other languages
-- (e.g. "no" in Spanish, "i" / "and" coincidences) are still included --
-- the ratio threshold absorbs a few coincidental hits.
local ENGLISH_MARKERS = {
    -- pronouns
    ["i"]=1, ["me"]=1, ["my"]=1, ["mine"]=1, ["myself"]=1,
    ["you"]=1, ["your"]=1, ["yours"]=1, ["yourself"]=1, ["yourselves"]=1,
    ["he"]=1, ["him"]=1, ["his"]=1, ["himself"]=1,
    ["she"]=1, ["her"]=1, ["hers"]=1, ["herself"]=1,
    ["it"]=1, ["its"]=1, ["itself"]=1,
    ["we"]=1, ["us"]=1, ["our"]=1, ["ours"]=1, ["ourselves"]=1,
    ["they"]=1, ["them"]=1, ["their"]=1, ["theirs"]=1, ["themselves"]=1,
    -- articles / demonstratives
    ["the"]=1, ["this"]=1, ["that"]=1, ["these"]=1, ["those"]=1,
    -- short distinctively-English particles (skipped: of=NL "or", do=PT "of the",
    -- in/on/an=DE/NL, no=ES, all 2-char where the conflict ratio is too high)
    ["is"]=1, ["to"]=1, ["be"]=1, ["by"]=1, ["if"]=1, ["as"]=1,
    ["or"]=1, ["so"]=1, ["at"]=1, ["go"]=1,
    -- copula / aux
    ["am"]=1, ["are"]=1, ["was"]=1, ["were"]=1, ["been"]=1, ["being"]=1,
    ["have"]=1, ["has"]=1, ["had"]=1, ["having"]=1,
    ["does"]=1, ["did"]=1, ["doing"]=1, ["done"]=1,
    ["will"]=1, ["would"]=1, ["shall"]=1, ["should"]=1,
    ["can"]=1, ["could"]=1, ["may"]=1, ["might"]=1, ["must"]=1,
    -- prepositions (3+ chars to avoid romance/germanic overlap)
    ["with"]=1, ["from"]=1, ["into"]=1, ["onto"]=1, ["upon"]=1, ["over"]=1,
    ["under"]=1, ["above"]=1, ["below"]=1, ["after"]=1, ["before"]=1,
    ["through"]=1, ["between"]=1, ["among"]=1, ["against"]=1, ["during"]=1,
    ["without"]=1, ["within"]=1, ["about"]=1,
    ["for"]=1, ["off"]=1, ["out"]=1,
    -- conjunctions
    ["and"]=1, ["but"]=1, ["because"]=1, ["while"]=1, ["since"]=1,
    ["although"]=1, ["though"]=1, ["unless"]=1, ["until"]=1, ["whether"]=1,
    -- interrogatives / wh-
    ["what"]=1, ["where"]=1, ["when"]=1, ["why"]=1, ["how"]=1,
    ["who"]=1, ["whom"]=1, ["whose"]=1, ["which"]=1,
    -- quantifiers
    ["any"]=1, ["some"]=1, ["all"]=1, ["both"]=1, ["each"]=1, ["every"]=1,
    ["other"]=1, ["another"]=1, ["such"]=1, ["many"]=1, ["much"]=1, ["few"]=1,
    -- time / place adverbs
    ["here"]=1, ["there"]=1, ["now"]=1, ["then"]=1,
    ["today"]=1, ["yesterday"]=1, ["tomorrow"]=1,
    ["just"]=1, ["only"]=1, ["also"]=1, ["too"]=1, ["very"]=1, ["really"]=1,
    ["always"]=1, ["never"]=1, ["sometimes"]=1, ["often"]=1,
    -- comparison
    ["more"]=1, ["most"]=1, ["less"]=1, ["least"]=1, ["than"]=1,
    -- common verbs (English-distinctive forms)
    ["get"]=1, ["got"]=1, ["gets"]=1, ["getting"]=1,
    ["want"]=1, ["wants"]=1, ["wanted"]=1, ["wanting"]=1,
    ["need"]=1, ["needs"]=1, ["needed"]=1, ["needing"]=1,
    ["like"]=1, ["liked"]=1, ["likes"]=1, ["liking"]=1,
    ["know"]=1, ["knew"]=1, ["known"]=1, ["knows"]=1,
    ["think"]=1, ["thinking"]=1, ["thought"]=1,
    ["going"]=1, ["went"]=1, ["gone"]=1,
    ["coming"]=1, ["came"]=1,
    ["make"]=1, ["made"]=1, ["makes"]=1, ["making"]=1,
    ["take"]=1, ["took"]=1, ["taken"]=1, ["taking"]=1,
    ["give"]=1, ["gave"]=1, ["given"]=1, ["giving"]=1,
    ["look"]=1, ["looked"]=1, ["looking"]=1, ["looks"]=1,
    ["help"]=1, ["helped"]=1, ["helping"]=1, ["helps"]=1,
    -- common chat words
    ["yes"]=1, ["yeah"]=1, ["nope"]=1, ["maybe"]=1,
    ["please"]=1, ["thanks"]=1, ["sorry"]=1, ["hello"]=1, ["hey"]=1,
    ["okay"]=1,
    -- negation (note: "no" overlaps Spanish, but ratio absorbs it)
    ["not"]=1,
    -- adverbs / generic intensifiers
    ["again"]=1, ["still"]=1, ["ever"]=1, ["even"]=1, ["anyway"]=1,
    ["actually"]=1, ["literally"]=1, ["basically"]=1, ["usually"]=1, ["finally"]=1,
    ["definitely"]=1, ["probably"]=1, ["obviously"]=1, ["totally"]=1, ["completely"]=1,
    ["exactly"]=1, ["mostly"]=1, ["almost"]=1, ["suddenly"]=1, ["pretty"]=1,
    -- compound pronouns / adverbs
    ["something"]=1, ["anything"]=1, ["nothing"]=1, ["everything"]=1,
    ["someone"]=1, ["anyone"]=1, ["everyone"]=1, ["nobody"]=1, ["somebody"]=1,
    ["somewhere"]=1, ["nowhere"]=1, ["everywhere"]=1, ["anywhere"]=1,
    -- casual adjectives
    ["good"]=1, ["bad"]=1, ["nice"]=1, ["cool"]=1, ["great"]=1, ["awesome"]=1,
    ["funny"]=1, ["weird"]=1, ["stupid"]=1, ["smart"]=1, ["dumb"]=1,
    ["huge"]=1, ["tiny"]=1, ["small"]=1, ["large"]=1, ["old"]=1, ["new"]=1,
    -- common verbs (more)
    ["talk"]=1, ["talks"]=1, ["talked"]=1, ["talking"]=1,
    ["say"]=1, ["says"]=1, ["said"]=1, ["saying"]=1,
    ["tell"]=1, ["tells"]=1, ["told"]=1, ["telling"]=1,
    ["ask"]=1, ["asks"]=1, ["asked"]=1, ["asking"]=1,
    ["play"]=1, ["plays"]=1, ["played"]=1, ["playing"]=1,
    ["work"]=1, ["works"]=1, ["worked"]=1, ["working"]=1,
    ["run"]=1, ["runs"]=1, ["ran"]=1, ["running"]=1,
    ["use"]=1, ["uses"]=1, ["used"]=1, ["using"]=1,
    -- people words
    ["guys"]=1, ["dude"]=1, ["dudes"]=1, ["folks"]=1, ["people"]=1,
    -- slang -in forms
    ["talkin"]=1, ["doin"]=1, ["goin"]=1, ["makin"]=1, ["comin"]=1,
    ["lookin"]=1, ["workin"]=1, ["runnin"]=1,
    -- WoW LFG / trade chat shorthand (distinctively English; foreign players
    -- use the gameplay loanwords "tank"/"dps"/"raid" but rarely these)
    ["lf"]=1, ["lfg"]=1, ["lfm"]=1, ["lf2m"]=1, ["lf3m"]=1, ["lf4m"]=1, ["lf5m"]=1,
    ["wts"]=1, ["wtb"]=1, ["wtt"]=1, ["wta"]=1,
    ["pst"]=1, ["afk"]=1, ["brb"]=1, ["gtg"]=1, ["bbl"]=1, ["ttyl"]=1, ["asap"]=1,
    -- selective WoW jargon
    ["lvl"]=1, ["spec"]=1, ["specs"]=1,
    -- crafting verbs (distinctively English; foreign players use native verbs
    -- like "stworzyć"/"crear"/"sozdat" -- "craft" is an English-coded ask)
    ["craft"]=1, ["crafts"]=1, ["crafted"]=1, ["crafting"]=1,
    ["enchant"]=1, ["enchants"]=1, ["enchanted"]=1, ["enchanting"]=1,
    ["create"]=1, ["creates"]=1, ["created"]=1, ["creating"]=1,
    ["build"]=1, ["builds"]=1, ["built"]=1, ["building"]=1,
    -- gear nouns (distinctively English spellings)
    ["armor"]=1, ["armour"]=1, ["weapon"]=1, ["weapons"]=1,
    -- profession names (distinctively English compound words)
    ["blacksmith"]=1, ["tailor"]=1, ["enchanter"]=1, ["leatherworker"]=1,
    ["jewelcrafter"]=1, ["alchemist"]=1, ["herbalist"]=1, ["skinner"]=1,
    ["miner"]=1, ["fisher"]=1, ["fishing"]=1, ["mining"]=1, ["skinning"]=1,
    ["smelting"]=1, ["forging"]=1, ["smithing"]=1,
    -- profession abbreviations (3+ chars only -- the ratio function ignores
    -- 2-char tokens, so "bs"/"jc"/"lw" wouldn't help even if added)
    ["ench"]=1, ["alch"]=1,
    -- chat slang / acknowledgements
    ["omg"]=1, ["lol"]=1, ["lmao"]=1, ["rofl"]=1, ["gg"]=1,
    ["btw"]=1, ["imo"]=1, ["imho"]=1, ["tbh"]=1, ["idk"]=1, ["idc"]=1,
    ["ngl"]=1, ["smh"]=1, ["wtf"]=1, ["np"]=1, ["nvm"]=1,
    ["pls"]=1, ["plz"]=1, ["ty"]=1, ["thx"]=1, ["ok"]=1,
}

local ENGLISH_MIN_TOKENS = 7           -- only check messages with this many tokens or more
local ENGLISH_MIN_RATIO  = 10          -- percent of tokens that must be English markers

-- Flag long messages that are conspicuously short on English function words.
-- Catches Spanish, Portuguese, Italian, French, German, Dutch, Polish, Czech,
-- transliterated Russian that slipped past detector 2, etc. -- without per-
-- language lists.
--
-- The ratio is computed over 3+ char tokens only. Polish/Slavic function words
-- like "to", "by", "my", "do", "na" coincide with English particles, so 1-2
-- char tokens drive the ratio up artificially. Restricting to 3+ ignores that
-- noise. The 7-token gate uses raw count, so short-token-heavy messages still
-- qualify for inspection.
local function is_low_english_density(text)
    if not text or text == "" then return false end
    local normalized = normalize_for_dict(text)
    local total, long_total, hits = 0, 0, 0
    for word in string.gmatch(normalized, "[%a]+") do
        total = total + 1
        if #word >= 3 then
            long_total = long_total + 1
            if ENGLISH_MARKERS[word] then hits = hits + 1 end
        end
    end
    if total < ENGLISH_MIN_TOKENS then return false end
    if long_total == 0 then return false end  -- can't determine; default to keep
    return (hits * 100 / long_total) < ENGLISH_MIN_RATIO
end

----------------------------------------------------------------------
-- Cache (ring buffer)
----------------------------------------------------------------------

local cache = {}
local cache_next_id = 1

local function cache_stash(entry)
    local id = cache_next_id
    cache[id] = entry
    cache_next_id = id + 1
    local cutoff = id - CACHE_SIZE
    if cutoff > 0 then cache[cutoff] = nil end
    return id
end

local function cache_get(id)
    return cache[id]
end

----------------------------------------------------------------------
-- Filter
----------------------------------------------------------------------

local function chat_filter(self, event, msg, ...)
    if not DB or not DB.enabled then return end
    if not msg or msg == "" then return end

    -- Three detectors, fastest first. Any one firing is enough to flag.
    local ok, foreign = pcall(is_likely_foreign, msg, DB.threshold)
    if not ok then return end
    if not foreign then
        local ok2, translit = pcall(is_transliterated_russian, msg)
        if not ok2 then return end
        if not translit then
            local ok3, sparse = pcall(is_low_english_density, msg)
            if not ok3 or not sparse then return end
        end
    end

    local sender = ...
    local channel = select(3, ...)
    if not channel or channel == "" then channel = event end

    local id = cache_stash({
        sender  = sender,
        channel = channel,
        msg     = msg,
        time    = time(),
    })

    local stub = string.format("|Hnsh:%d|h%s|h", id, STUB_TEXT)
    return false, stub, ...
end

----------------------------------------------------------------------
-- Hyperlink (click + hover)
----------------------------------------------------------------------

local function looks_like_ours(link)
    return link and string.sub(link, 1, 4) == LINK_PREFIX
end

local original_SetItemRef = SetItemRef
SetItemRef = function(link, text, button, ...)
    if looks_like_ours(link) then
        local id = tonumber(string.sub(link, 5))
        local entry = id and cache_get(id)
        local frame = DEFAULT_CHAT_FRAME
        if entry then
            frame:AddMessage(string.format(
                "|cff888888[shown]|r %s%s|r: %s",
                "|cffaaaaff", entry.sender or "?", entry.msg))
        else
            frame:AddMessage("|cffff5555[No Se Habla]|r message no longer available")
        end
        return
    end
    return original_SetItemRef(link, text, button, ...)
end

local function on_hyperlink_enter(self, link)
    if not looks_like_ours(link) then return end
    local id = tonumber(string.sub(link, 5))
    local entry = id and cache_get(id)
    if not entry then return end

    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
    GameTooltip:AddLine(entry.sender or "?", 1, 1, 1)
    if entry.channel and entry.channel ~= "" then
        GameTooltip:AddLine(entry.channel, 0.6, 0.6, 0.6)
    end
    local preview = entry.msg
    if #preview > 240 then preview = string.sub(preview, 1, 240) .. "..." end
    GameTooltip:AddLine(preview, 0.85, 0.85, 0.85, true)
    GameTooltip:Show()
end

local function on_hyperlink_leave(self)
    GameTooltip:Hide()
end

----------------------------------------------------------------------
-- Slash commands
----------------------------------------------------------------------

local function announce(s)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff[No Se Habla]|r " .. s)
end

local function slash_handler(input)
    input = string.lower(input or "")
    input = string.gsub(input, "^%s+", "")
    input = string.gsub(input, "%s+$", "")
    local cmd, arg = string.match(input, "^(%S+)%s*(.*)$")
    cmd = cmd or ""

    if cmd == "" or cmd == "status" then
        announce(string.format(
            "%s, threshold %d%%, %d cached.",
            DB.enabled and "ON" or "OFF",
            DB.threshold,
            cache_next_id - 1))

    elseif cmd == "on" then
        DB.enabled = true
        announce("enabled.")

    elseif cmd == "off" then
        DB.enabled = false
        announce("disabled.")

    elseif cmd == "toggle" then
        DB.enabled = not DB.enabled
        announce(DB.enabled and "enabled." or "disabled.")

    elseif cmd == "threshold" then
        local n = tonumber(arg)
        if n and n >= 0 and n <= 100 then
            DB.threshold = n
            announce("threshold set to " .. n .. "%.")
        else
            announce("usage: /nsh threshold <0-100>")
        end

    elseif cmd == "last" then
        local n = tonumber(arg) or 5
        local shown = 0
        for id = cache_next_id - 1, 1, -1 do
            if shown >= n then break end
            local e = cache[id]
            if e then
                DEFAULT_CHAT_FRAME:AddMessage(string.format(
                    "|cff888888[%d]|r %s [%s]: %s",
                    id, e.sender or "?", e.channel or "?", e.msg))
                shown = shown + 1
            end
        end
        if shown == 0 then announce("no suppressed messages.") end

    else
        announce("commands: on | off | toggle | status | threshold <0-100> | last [N]")
    end
end

----------------------------------------------------------------------
-- Init
----------------------------------------------------------------------

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name == ADDON_NAME then
        if type(NoSeHablaDB) ~= "table" then NoSeHablaDB = defaults() end
        DB = NoSeHablaDB
        for k, v in pairs(defaults()) do
            if DB[k] == nil then DB[k] = v end
        end

    elseif event == "PLAYER_LOGIN" then
        for _, evt in ipairs(CHANNEL_EVENTS) do
            ChatFrame_AddMessageEventFilter(evt, chat_filter)
        end
        for i = 1, NUM_CHAT_WINDOWS do
            local cf = _G["ChatFrame" .. i]
            if cf then
                cf:HookScript("OnHyperlinkEnter", on_hyperlink_enter)
                cf:HookScript("OnHyperlinkLeave", on_hyperlink_leave)
            end
        end
        SLASH_NOSEHABLA1 = "/nsh"
        SLASH_NOSEHABLA2 = "/nosehabla"
        SlashCmdList["NOSEHABLA"] = slash_handler
        announce("loaded. /nsh for commands.")
    end
end)
