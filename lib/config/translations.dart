import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': _en,
    'fr_FR': _fr,
    'es_ES': _es,
    'pt_BR': _pt,
    'ar_SA': _ar,
    'zh_CN': _zh,
    'de_DE': _de,
    'yo_NG': _yo,
  };
}

// ── English ──────────────────────────────────────────────────────────────────
const _en = {
  // Nav
  'nav_library': 'Library',
  'nav_explorer': 'Explorer',
  'nav_genres': 'Genres',
  'nav_me': 'Me',

  // Header
  'btn_check_in': 'Check In',
  'search_hint': 'Search novels, authors, genres...',
  'select_language': 'Select Language',

  // Sections
  'section_weekly_featured': 'Weekly Featured',
  'section_for_you': 'For You',
  'section_best_novels': 'Best Novels',
  'section_trending': 'Trending Now',
  'section_completed': 'Completed Stories',
  'section_world_famous': 'World Famous',
  'section_free_download': 'Free Download',
  'section_african_folktale': 'African Folk Tale',
  'section_editors_pick': "Editor's Pick",
  'section_new_arrivals': 'New Arrivals',
  'section_recommended': 'Recommended For You',
  'section_short_stories': 'Short Stories',
  'section_free_discount': 'Free & Discount',
  'section_rankings': 'Rankings',
  'section_author_spotlight': 'Author Spotlight',
  'section_featured_for_you': 'Featured For You',

  // Sort / filter tabs
  'tab_most_read': 'Most Read',
  'tab_most_engaging': 'Most Engaging',
  'tab_top_rated': 'Top Rated',
  'tab_top_buzz': 'Top Buzz',
  'tab_top_earners': 'Top Earners',
  'tab_top_completed': 'Top Completed',
  'tab_all_time': 'All Time',
  'tab_monthly': 'Monthly',
  'tab_weekly': 'Weekly',
  'tab_daily': 'Daily',

  // Ranking page
  'ranking_new_releases': 'New Releases',
  'ranking_most_read': 'Most Read',
  'ranking_must_read': 'Must Read',
  'ranking_popularity': 'Popularity',
  'ranking_daily_releases': 'Daily Releases',
  'ranking_rising': 'Rising',
  'ranking_short_stories': 'Short Stories',
  'ranking_more': 'More',

  // Genre tabs
  'genre_hot': '🔥 Hot',
  'genre_werewolf': '🐺 Werewolf',
  'genre_billionaire': '💎 Billionaire',
  'genre_short_fics': '📖 Short Fics',
  'genre_ranking': '🏆 Ranking',
  'genre_for_her': '💕 For Her',
  'genre_for_him': '💪 For Him',
  'genre_suspense': '😱 Suspense',

  // Buttons & common
  'btn_view_all': 'View all',
  'btn_continue': 'Continue',
  'last_read': 'Last read: Chapter',

  // Free & Discount banner
  'free_24h': '24 HOURS FREE',
  'free_24h_sub': "Don't miss out!\nNew stories every day.",

  // Empty / error
  'empty_no_stories': 'No stories found',
  'empty_pull_refresh': 'Nothing here yet — pull to refresh',

  // Search placeholders
  'search_p1': 'The Ashboard Crown',
  'search_p2': 'Sweet chaos',
  'search_p3': "Luna's betrayal",
  'search_p4': 'Unexpected desires',
};

// ── French ───────────────────────────────────────────────────────────────────
const _fr = {
  'nav_library': 'Bibliothèque',
  'nav_explorer': 'Explorer',
  'nav_genres': 'Genres',
  'nav_me': 'Moi',

  'btn_check_in': 'Connexion',
  'search_hint': 'Rechercher romans, auteurs, genres...',
  'select_language': 'Choisir la langue',

  'section_weekly_featured': 'Sélection de la Semaine',
  'section_for_you': 'Pour Vous',
  'section_best_novels': 'Meilleurs Romans',
  'section_trending': 'Tendances',
  'section_completed': 'Histoires Complètes',
  'section_world_famous': 'Mondialement Célèbre',
  'section_free_download': 'Téléchargement Gratuit',
  'section_african_folktale': 'Contes Africains',
  'section_editors_pick': "Choix de l'Éditeur",
  'section_new_arrivals': 'Nouveautés',
  'section_recommended': 'Recommandé Pour Vous',
  'section_short_stories': 'Nouvelles',
  'section_free_discount': 'Gratuit & Promo',
  'section_rankings': 'Classements',
  'section_author_spotlight': 'Auteur en Vedette',
  'section_featured_for_you': 'Sélectionné Pour Vous',

  'tab_most_read': 'Plus Lus',
  'tab_most_engaging': 'Plus Engageants',
  'tab_top_rated': 'Mieux Notés',
  'tab_top_buzz': 'Top Buzz',
  'tab_top_earners': 'Meilleurs Gains',
  'tab_top_completed': 'Complétés',
  'tab_all_time': 'Tous les Temps',
  'tab_monthly': 'Mensuel',
  'tab_weekly': 'Hebdomadaire',
  'tab_daily': 'Quotidien',

  'ranking_new_releases': 'Nouvelles Sorties',
  'ranking_most_read': 'Plus Lus',
  'ranking_must_read': 'À Lire',
  'ranking_popularity': 'Popularité',
  'ranking_daily_releases': 'Sorties Quotidiennes',
  'ranking_rising': 'En Hausse',
  'ranking_short_stories': 'Nouvelles',
  'ranking_more': 'Plus',

  'genre_hot': '🔥 Populaire',
  'genre_werewolf': '🐺 Loup-Garou',
  'genre_billionaire': '💎 Milliardaire',
  'genre_short_fics': '📖 Courtes',
  'genre_ranking': '🏆 Classement',
  'genre_for_her': '💕 Pour Elle',
  'genre_for_him': '💪 Pour Lui',
  'genre_suspense': '😱 Suspense',

  'btn_view_all': 'Voir tout',
  'btn_continue': 'Continuer',
  'last_read': 'Dernier chapitre:',

  'free_24h': '24 HEURES GRATUITES',
  'free_24h_sub': "Ne ratez pas!\nDe nouvelles histoires chaque jour.",

  'empty_no_stories': 'Aucune histoire trouvée',
  'empty_pull_refresh': 'Rien ici encore — tirez pour actualiser',

  'search_p1': 'The Ashboard Crown',
  'search_p2': 'Sweet chaos',
  'search_p3': "Luna's betrayal",
  'search_p4': 'Unexpected desires',
};

// ── Spanish ──────────────────────────────────────────────────────────────────
const _es = {
  'nav_library': 'Biblioteca',
  'nav_explorer': 'Explorar',
  'nav_genres': 'Géneros',
  'nav_me': 'Yo',

  'btn_check_in': 'Registrarse',
  'search_hint': 'Buscar novelas, autores, géneros...',
  'select_language': 'Seleccionar idioma',

  'section_weekly_featured': 'Destacado de la Semana',
  'section_for_you': 'Para Ti',
  'section_best_novels': 'Mejores Novelas',
  'section_trending': 'Tendencias',
  'section_completed': 'Historias Completas',
  'section_world_famous': 'Mundialmente Famoso',
  'section_free_download': 'Descarga Gratuita',
  'section_african_folktale': 'Cuentos Africanos',
  'section_editors_pick': 'Selección del Editor',
  'section_new_arrivals': 'Novedades',
  'section_recommended': 'Recomendado Para Ti',
  'section_short_stories': 'Cuentos Cortos',
  'section_free_discount': 'Gratis & Descuento',
  'section_rankings': 'Rankings',
  'section_author_spotlight': 'Autor Destacado',
  'section_featured_for_you': 'Seleccionado Para Ti',

  'tab_most_read': 'Más Leídos',
  'tab_most_engaging': 'Más Atractivos',
  'tab_top_rated': 'Mejor Valorados',
  'tab_top_buzz': 'Top Buzz',
  'tab_top_earners': 'Top Ganancias',
  'tab_top_completed': 'Completados',
  'tab_all_time': 'Siempre',
  'tab_monthly': 'Mensual',
  'tab_weekly': 'Semanal',
  'tab_daily': 'Diario',

  'ranking_new_releases': 'Nuevos Lanzamientos',
  'ranking_most_read': 'Más Leídos',
  'ranking_must_read': 'Lectura Obligada',
  'ranking_popularity': 'Popularidad',
  'ranking_daily_releases': 'Lanzamientos Diarios',
  'ranking_rising': 'En Alza',
  'ranking_short_stories': 'Cuentos Cortos',
  'ranking_more': 'Más',

  'genre_hot': '🔥 Popular',
  'genre_werewolf': '🐺 Hombre Lobo',
  'genre_billionaire': '💎 Millonario',
  'genre_short_fics': '📖 Cortos',
  'genre_ranking': '🏆 Ranking',
  'genre_for_her': '💕 Para Ella',
  'genre_for_him': '💪 Para Él',
  'genre_suspense': '😱 Suspenso',

  'btn_view_all': 'Ver todo',
  'btn_continue': 'Continuar',
  'last_read': 'Último capítulo:',

  'free_24h': '24 HORAS GRATIS',
  'free_24h_sub': "¡No te lo pierdas!\nNuevas historias cada día.",

  'empty_no_stories': 'No se encontraron historias',
  'empty_pull_refresh': 'Nada aquí aún — desliza para actualizar',

  'search_p1': 'The Ashboard Crown',
  'search_p2': 'Sweet chaos',
  'search_p3': "Luna's betrayal",
  'search_p4': 'Unexpected desires',
};

// ── Portuguese (Brazil) ───────────────────────────────────────────────────────
const _pt = {
  'nav_library': 'Biblioteca',
  'nav_explorer': 'Explorar',
  'nav_genres': 'Gêneros',
  'nav_me': 'Eu',

  'btn_check_in': 'Check-in',
  'search_hint': 'Buscar romances, autores, gêneros...',
  'select_language': 'Selecionar idioma',

  'section_weekly_featured': 'Destaque da Semana',
  'section_for_you': 'Para Você',
  'section_best_novels': 'Melhores Romances',
  'section_trending': 'Em Alta',
  'section_completed': 'Histórias Completas',
  'section_world_famous': 'Mundialmente Famoso',
  'section_free_download': 'Download Gratuito',
  'section_african_folktale': 'Contos Africanos',
  'section_editors_pick': 'Escolha do Editor',
  'section_new_arrivals': 'Novidades',
  'section_recommended': 'Recomendado Para Você',
  'section_short_stories': 'Contos',
  'section_free_discount': 'Grátis & Desconto',
  'section_rankings': 'Rankings',
  'section_author_spotlight': 'Autor em Destaque',
  'section_featured_for_you': 'Selecionado Para Você',

  'tab_most_read': 'Mais Lidos',
  'tab_most_engaging': 'Mais Envolventes',
  'tab_top_rated': 'Melhor Avaliados',
  'tab_top_buzz': 'Top Buzz',
  'tab_top_earners': 'Mais Rentáveis',
  'tab_top_completed': 'Completos',
  'tab_all_time': 'Todos os Tempos',
  'tab_monthly': 'Mensal',
  'tab_weekly': 'Semanal',
  'tab_daily': 'Diário',

  'ranking_new_releases': 'Novos Lançamentos',
  'ranking_most_read': 'Mais Lidos',
  'ranking_must_read': 'Leitura Obrigatória',
  'ranking_popularity': 'Popularidade',
  'ranking_daily_releases': 'Lançamentos Diários',
  'ranking_rising': 'Em Ascensão',
  'ranking_short_stories': 'Contos',
  'ranking_more': 'Mais',

  'genre_hot': '🔥 Popular',
  'genre_werewolf': '🐺 Lobisomem',
  'genre_billionaire': '💎 Bilionário',
  'genre_short_fics': '📖 Contos',
  'genre_ranking': '🏆 Ranking',
  'genre_for_her': '💕 Para Ela',
  'genre_for_him': '💪 Para Ele',
  'genre_suspense': '😱 Suspense',

  'btn_view_all': 'Ver tudo',
  'btn_continue': 'Continuar',
  'last_read': 'Último capítulo:',

  'free_24h': '24 HORAS GRÁTIS',
  'free_24h_sub': "Não perca!\nNovas histórias todo dia.",

  'empty_no_stories': 'Nenhuma história encontrada',
  'empty_pull_refresh': 'Nada aqui ainda — puxe para atualizar',

  'search_p1': 'The Ashboard Crown',
  'search_p2': 'Sweet chaos',
  'search_p3': "Luna's betrayal",
  'search_p4': 'Unexpected desires',
};

// ── Arabic ───────────────────────────────────────────────────────────────────
const _ar = {
  'nav_library': 'المكتبة',
  'nav_explorer': 'استكشاف',
  'nav_genres': 'الأنواع',
  'nav_me': 'أنا',

  'btn_check_in': 'تسجيل الدخول',
  'search_hint': 'ابحث عن روايات، كتّاب، أنواع...',
  'select_language': 'اختر اللغة',

  'section_weekly_featured': 'مميز الأسبوع',
  'section_for_you': 'لأجلك',
  'section_best_novels': 'أفضل الروايات',
  'section_trending': 'الرائج الآن',
  'section_completed': 'قصص مكتملة',
  'section_world_famous': 'مشهور عالمياً',
  'section_free_download': 'تحميل مجاني',
  'section_african_folktale': 'حكايات أفريقية',
  'section_editors_pick': 'اختيار المحرر',
  'section_new_arrivals': 'وصل حديثاً',
  'section_recommended': 'موصى به لك',
  'section_short_stories': 'قصص قصيرة',
  'section_free_discount': 'مجاني وخصومات',
  'section_rankings': 'التصنيفات',
  'section_author_spotlight': 'كاتب مميز',
  'section_featured_for_you': 'مختار لك',

  'tab_most_read': 'الأكثر قراءة',
  'tab_most_engaging': 'الأكثر تفاعلاً',
  'tab_top_rated': 'الأعلى تقييماً',
  'tab_top_buzz': 'الأكثر ضجة',
  'tab_top_earners': 'الأعلى ربحاً',
  'tab_top_completed': 'المكتملة',
  'tab_all_time': 'كل الأوقات',
  'tab_monthly': 'شهري',
  'tab_weekly': 'أسبوعي',
  'tab_daily': 'يومي',

  'ranking_new_releases': 'إصدارات جديدة',
  'ranking_most_read': 'الأكثر قراءة',
  'ranking_must_read': 'يجب قراءتها',
  'ranking_popularity': 'الشعبية',
  'ranking_daily_releases': 'إصدارات يومية',
  'ranking_rising': 'في صعود',
  'ranking_short_stories': 'قصص قصيرة',
  'ranking_more': 'المزيد',

  'genre_hot': '🔥 رائج',
  'genre_werewolf': '🐺 مستذئب',
  'genre_billionaire': '💎 مليارديرة',
  'genre_short_fics': '📖 قصص قصيرة',
  'genre_ranking': '🏆 تصنيف',
  'genre_for_her': '💕 لها',
  'genre_for_him': '💪 له',
  'genre_suspense': '😱 إثارة',

  'btn_view_all': 'عرض الكل',
  'btn_continue': 'متابعة',
  'last_read': 'آخر قراءة: الفصل',

  'free_24h': '٢٤ ساعة مجاناً',
  'free_24h_sub': 'لا تفوّت الفرصة!\nقصص جديدة كل يوم.',

  'empty_no_stories': 'لا توجد قصص',
  'empty_pull_refresh': 'لا يوجد شيء هنا — اسحب للتحديث',

  'search_p1': 'The Ashboard Crown',
  'search_p2': 'Sweet chaos',
  'search_p3': "Luna's betrayal",
  'search_p4': 'Unexpected desires',
};

// ── Chinese Simplified ────────────────────────────────────────────────────────
const _zh = {
  'nav_library': '书库',
  'nav_explorer': '探索',
  'nav_genres': '类型',
  'nav_me': '我',

  'btn_check_in': '签到',
  'search_hint': '搜索小说、作者、类型...',
  'select_language': '选择语言',

  'section_weekly_featured': '本周精选',
  'section_for_you': '为你推荐',
  'section_best_novels': '最佳小说',
  'section_trending': '热门趋势',
  'section_completed': '已完结',
  'section_world_famous': '世界名著',
  'section_free_download': '免费下载',
  'section_african_folktale': '非洲民间故事',
  'section_editors_pick': '编辑精选',
  'section_new_arrivals': '新书上架',
  'section_recommended': '为你推荐',
  'section_short_stories': '短篇小说',
  'section_free_discount': '免费与折扣',
  'section_rankings': '排行榜',
  'section_author_spotlight': '作者推荐',
  'section_featured_for_you': '精选推荐',

  'tab_most_read': '最多阅读',
  'tab_most_engaging': '最受欢迎',
  'tab_top_rated': '评分最高',
  'tab_top_buzz': '热议',
  'tab_top_earners': '收益最高',
  'tab_top_completed': '已完结',
  'tab_all_time': '全部时间',
  'tab_monthly': '月榜',
  'tab_weekly': '周榜',
  'tab_daily': '日榜',

  'ranking_new_releases': '新书发布',
  'ranking_most_read': '最多阅读',
  'ranking_must_read': '必读',
  'ranking_popularity': '人气',
  'ranking_daily_releases': '每日新书',
  'ranking_rising': '上升中',
  'ranking_short_stories': '短篇小说',
  'ranking_more': '更多',

  'genre_hot': '🔥 热门',
  'genre_werewolf': '🐺 狼人',
  'genre_billionaire': '💎 亿万富翁',
  'genre_short_fics': '📖 短篇',
  'genre_ranking': '🏆 排行',
  'genre_for_her': '💕 她的故事',
  'genre_for_him': '💪 他的故事',
  'genre_suspense': '😱 悬疑',

  'btn_view_all': '查看全部',
  'btn_continue': '继续',
  'last_read': '上次读到：第',

  'free_24h': '24小时免费',
  'free_24h_sub': '不要错过！\n每天都有新故事。',

  'empty_no_stories': '暂无故事',
  'empty_pull_refresh': '暂时没有内容 — 下拉刷新',

  'search_p1': 'The Ashboard Crown',
  'search_p2': 'Sweet chaos',
  'search_p3': "Luna's betrayal",
  'search_p4': 'Unexpected desires',
};

// ── German ───────────────────────────────────────────────────────────────────
const _de = {
  'nav_library': 'Bibliothek',
  'nav_explorer': 'Entdecken',
  'nav_genres': 'Genres',
  'nav_me': 'Ich',

  'btn_check_in': 'Einchecken',
  'search_hint': 'Romane, Autoren, Genres suchen...',
  'select_language': 'Sprache wählen',

  'section_weekly_featured': 'Wöchentliche Highlights',
  'section_for_you': 'Für Dich',
  'section_best_novels': 'Beste Romane',
  'section_trending': 'Trends',
  'section_completed': 'Abgeschlossene Geschichten',
  'section_world_famous': 'Weltberühmt',
  'section_free_download': 'Kostenloser Download',
  'section_african_folktale': 'Afrikanische Volksgeschichten',
  'section_editors_pick': "Redaktionsauswahl",
  'section_new_arrivals': 'Neuerscheinungen',
  'section_recommended': 'Empfohlen für Dich',
  'section_short_stories': 'Kurzgeschichten',
  'section_free_discount': 'Kostenlos & Rabatt',
  'section_rankings': 'Rankings',
  'section_author_spotlight': 'Autor im Rampenlicht',
  'section_featured_for_you': 'Ausgewählt für Dich',

  'tab_most_read': 'Meistgelesen',
  'tab_most_engaging': 'Beliebteste',
  'tab_top_rated': 'Beste Bewertung',
  'tab_top_buzz': 'Top Buzz',
  'tab_top_earners': 'Top Einnahmen',
  'tab_top_completed': 'Abgeschlossen',
  'tab_all_time': 'Alle Zeit',
  'tab_monthly': 'Monatlich',
  'tab_weekly': 'Wöchentlich',
  'tab_daily': 'Täglich',

  'ranking_new_releases': 'Neuerscheinungen',
  'ranking_most_read': 'Meistgelesen',
  'ranking_must_read': 'Pflichtlektüre',
  'ranking_popularity': 'Beliebtheit',
  'ranking_daily_releases': 'Tägliche Releases',
  'ranking_rising': 'Im Aufstieg',
  'ranking_short_stories': 'Kurzgeschichten',
  'ranking_more': 'Mehr',

  'genre_hot': '🔥 Heiß',
  'genre_werewolf': '🐺 Werwolf',
  'genre_billionaire': '💎 Milliardär',
  'genre_short_fics': '📖 Kurzform',
  'genre_ranking': '🏆 Ranking',
  'genre_for_her': '💕 Für Sie',
  'genre_for_him': '💪 Für Ihn',
  'genre_suspense': '😱 Spannung',

  'btn_view_all': 'Alle ansehen',
  'btn_continue': 'Weiter',
  'last_read': 'Zuletzt gelesen: Kapitel',

  'free_24h': '24 STUNDEN GRATIS',
  'free_24h_sub': 'Nicht verpassen!\nTäglich neue Geschichten.',

  'empty_no_stories': 'Keine Geschichten gefunden',
  'empty_pull_refresh': 'Noch nichts hier — zum Aktualisieren ziehen',

  'search_p1': 'The Ashboard Crown',
  'search_p2': 'Sweet chaos',
  'search_p3': "Luna's betrayal",
  'search_p4': 'Unexpected desires',
};

// ── Yoruba ───────────────────────────────────────────────────────────────────
const _yo = {
  'nav_library': 'Ile-ikawe',
  'nav_explorer': 'Ṣàwárí',
  'nav_genres': 'Iru',
  'nav_me': 'Èmi',

  'btn_check_in': 'Forúkọsílẹ̀',
  'search_hint': 'Ṣàwárí ìtàn, àwọn òǹkọ̀wé, ìrísí...',
  'select_language': 'Yan Èdè',

  'section_weekly_featured': 'Àṣàyàn Ọ̀sẹ̀',
  'section_for_you': 'Fún Ọ',
  'section_best_novels': 'Àwọn Ìtàn Tó Dára Jùlọ',
  'section_trending': 'Òkìkí Báyìí',
  'section_completed': 'Àwọn Ìtàn Tán',
  'section_world_famous': 'Olókìkí Ayé',
  'section_free_download': 'Gbèéfà Ọfẹ',
  'section_african_folktale': 'Àlọ́ Ilẹ̀ Áfríkà',
  'section_editors_pick': 'Àṣàyàn Olùṣàtúpalẹ̀',
  'section_new_arrivals': 'Tuntun Dé',
  'section_recommended': 'A Gbàní Mọ́ Fún Ọ',
  'section_short_stories': 'Ìtàn Kúkúrú',
  'section_free_discount': 'Ọfẹ & Ẹdinwò',
  'section_rankings': 'Ìtò',
  'section_author_spotlight': 'Òǹkọ̀wé Àṣàyàn',
  'section_featured_for_you': 'Àṣàyàn Fún Ọ',

  'tab_most_read': 'Tí A Ka Jùlọ',
  'tab_most_engaging': 'Tí Ó Wúni Jùlọ',
  'tab_top_rated': 'Tí A Ṣàpèjúwe Gíga',
  'tab_top_buzz': 'Ìtàn Gbígbajúmọ̀',
  'tab_top_earners': 'Àwọn Ẹlẹ́gbẹ̀ Ọlà',
  'tab_top_completed': 'Àwọn Tán',
  'tab_all_time': 'Gbogbo Àkókò',
  'tab_monthly': 'Oṣooṣu',
  'tab_weekly': 'Ọ̀sẹ̀ Kọ̀ọ̀kan',
  'tab_daily': 'Ọjọ́ Kọ̀ọ̀kan',

  'ranking_new_releases': 'Àwọn Tuntun',
  'ranking_most_read': 'Tí A Ka Jùlọ',
  'ranking_must_read': 'O Gbọdọ̀ Ka',
  'ranking_popularity': 'Olókìkí',
  'ranking_daily_releases': 'Ìtàn Ọjọ́ Kọ̀ọ̀kan',
  'ranking_rising': 'Tí Ó Ń Gòkè',
  'ranking_short_stories': 'Ìtàn Kúkúrú',
  'ranking_more': 'Síwájú Sí',

  'genre_hot': '🔥 Gbígbóná',
  'genre_werewolf': '🐺 Ìjǹà Ìkookò',
  'genre_billionaire': '💎 Olówó Pọ̀',
  'genre_short_fics': '📖 Ìtàn Kúkúrú',
  'genre_ranking': '🏆 Ìtò',
  'genre_for_her': '💕 Fún Obìnrin',
  'genre_for_him': '💪 Fún Okùnrin',
  'genre_suspense': '😱 Ẹ̀rú',

  'btn_view_all': 'Wò Gbogbo',
  'btn_continue': 'Tẹ̀síwájú',
  'last_read': 'Ìkàǹsí: Orí',

  'free_24h': 'ÌWÀ-ỌFẸ FÚN WÁKÀTÍ 24',
  'free_24h_sub': 'Má jẹ́ kí o padà!\nÀwọn ìtàn tuntun lójoojúmọ̀.',

  'empty_no_stories': 'Kò sí ìtàn',
  'empty_pull_refresh': 'Kò sí nǹkan níbí — fà sísàlẹ̀ láti tún ṣe',

  'search_p1': 'The Ashboard Crown',
  'search_p2': 'Sweet chaos',
  'search_p3': "Luna's betrayal",
  'search_p4': 'Unexpected desires',
};
