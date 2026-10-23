// SPDX-License-Identifier: GPL-3.0-or-later
#include "appindex.h"

#include <QCollator>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QLocale>
#include <QLoggingCategory>
#include <QProcess>
#include <QProcessEnvironment>
#include <QStandardPaths>
#include <QTextStream>
#include <algorithm>

Q_LOGGING_CATEGORY(lcApps, "minos.apps")

AppIndex::AppIndex(QObject *parent)
    : QAbstractListModel(parent)
{
    refresh();
}

int AppIndex::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_visible.size();
}

QVariant AppIndex::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_visible.size())
        return {};
    const AppEntry &e = m_all.at(m_visible.at(index.row()));
    switch (role) {
    case NameRole: return e.name;
    case CommentRole: return e.comment.isEmpty() ? e.genericName : e.comment;
    case IconRole: return e.icon;
    case ExecRole: return e.exec;
    case IdRole: return e.id;
    case TerminalRole: return e.terminal;
    case Qt::DisplayRole: return e.name;
    default: return {};
    }
}

QHash<int, QByteArray> AppIndex::roleNames() const
{
    return {
        { NameRole, "name" }, { CommentRole, "comment" }, { IconRole, "icon" },
        { ExecRole, "exec" }, { IdRole, "appId" }, { TerminalRole, "terminal" },
    };
}

void AppIndex::setFilter(const QString &filter)
{
    if (m_filter == filter)
        return;
    m_filter = filter;
    rebuildVisible();
    emit filterChanged();
}

void AppIndex::refresh()
{
    beginResetModel();
    m_all = scan(applicationDirs(), qEnvironmentVariable("XDG_CURRENT_DESKTOP", QStringLiteral("MIN")));
    endResetModel();
    rebuildVisible();
    qCInfo(lcApps) << "indexed" << m_all.size() << "applications";
}

void AppIndex::rebuildVisible()
{
    beginResetModel();
    m_visible.clear();
    const QString needle = m_filter.trimmed();
    QList<QPair<int, int>> scored; // (score, index)
    for (int i = 0; i < m_all.size(); ++i) {
        int score = 0;
        if (needle.isEmpty() || matchesFilter(m_all.at(i), needle, &score))
            scored.append({ score, i });
    }
    QCollator collator;
    collator.setCaseSensitivity(Qt::CaseInsensitive);
    collator.setNumericMode(true);
    std::stable_sort(scored.begin(), scored.end(), [&](const QPair<int, int> &a, const QPair<int, int> &b) {
        if (a.first != b.first)
            return a.first > b.first;
        return collator.compare(m_all.at(a.second).name, m_all.at(b.second).name) < 0;
    });
    for (const auto &p : scored)
        m_visible.append(p.second);
    endResetModel();
    emit countChanged();
}

bool AppIndex::matchesFilter(const AppEntry &e, const QString &needle, int *score)
{
    const Qt::CaseSensitivity cs = Qt::CaseInsensitive;
    int s = 0;
    if (e.name.startsWith(needle, cs)) s = 100;
    else if (e.name.contains(needle, cs)) s = 80;
    else if (e.genericName.contains(needle, cs)) s = 60;
    else {
        for (const QString &k : e.keywords)
            if (k.startsWith(needle, cs)) { s = 50; break; }
        if (s == 0 && e.comment.contains(needle, cs)) s = 30;
        if (s == 0 && QFileInfo(execToArgs(e.exec).value(0)).fileName().startsWith(needle, cs)) s = 40;
    }
    if (score) *score = s;
    return s > 0;
}

QStringList AppIndex::localeKeys()
{
    QStringList keys;
    const QString lang = qEnvironmentVariable("LC_MESSAGES", qEnvironmentVariable("LANG"));
    QString base = lang.section(QLatin1Char('.'), 0, 0).section(QLatin1Char('@'), 0, 0); // ko_KR
    if (base.isEmpty() || base == QLatin1String("C") || base == QLatin1String("POSIX"))
        base = QLocale::system().name();
    if (!base.isEmpty() && base != QLatin1String("C")) {
        keys << base;
        const QString l = base.section(QLatin1Char('_'), 0, 0);
        if (l != base) keys << l;
    }
    return keys;
}

QStringList AppIndex::applicationDirs()
{
    QStringList dirs;
    const QString dataHome = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
    if (!dataHome.isEmpty())
        dirs << dataHome + QStringLiteral("/applications");
    QString dataDirs = qEnvironmentVariable("XDG_DATA_DIRS");
    if (dataDirs.isEmpty())
        dataDirs = QStringLiteral("/usr/local/share:/usr/share");
    for (const QString &d : dataDirs.split(QLatin1Char(':'), Qt::SkipEmptyParts))
        dirs << QDir::cleanPath(d) + QStringLiteral("/applications");
    dirs.removeDuplicates();
    return dirs;
}

static QString unescapeValue(QString v)
{
    v.replace(QStringLiteral("\\s"), QStringLiteral(" "));
    v.replace(QStringLiteral("\\n"), QStringLiteral("\n"));
    v.replace(QStringLiteral("\\t"), QStringLiteral("\t"));
    v.replace(QStringLiteral("\\r"), QStringLiteral("\r"));
    v.replace(QStringLiteral("\\\\"), QStringLiteral("\\"));
    return v;
}

std::optional<AppEntry> AppIndex::parseDesktopFile(const QString &filePath, const QStringList &localeKeys)
{
    QFile f(filePath);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
        return std::nullopt;
    QTextStream in(&f);
    QHash<QString, QString> kv;
    bool inEntry = false;
    while (!in.atEnd()) {
        const QString line = in.readLine().trimmed();
        if (line.isEmpty() || line.startsWith(QLatin1Char('#')))
            continue;
        if (line.startsWith(QLatin1Char('['))) {
            inEntry = (line == QLatin1String("[Desktop Entry]"));
            continue;
        }
        if (!inEntry)
            continue;
        const int eq = line.indexOf(QLatin1Char('='));
        if (eq <= 0)
            continue;
        kv.insert(line.left(eq).trimmed(), line.mid(eq + 1).trimmed());
    }
    if (kv.value(QStringLiteral("Type"), QStringLiteral("Application")) != QLatin1String("Application"))
        return std::nullopt;

    auto localized = [&](const QString &key) {
        for (const QString &lk : localeKeys) {
            const QString k = key + QLatin1Char('[') + lk + QLatin1Char(']');
            if (kv.contains(k)) return unescapeValue(kv.value(k));
        }
        return unescapeValue(kv.value(key));
    };
    auto boolean = [&](const QString &key) { return kv.value(key).compare(QLatin1String("true"), Qt::CaseInsensitive) == 0; };

    AppEntry e;
    e.id = QFileInfo(filePath).completeBaseName();
    e.name = localized(QStringLiteral("Name"));
    e.genericName = localized(QStringLiteral("GenericName"));
    e.comment = localized(QStringLiteral("Comment"));
    e.icon = kv.value(QStringLiteral("Icon"));
    e.exec = kv.value(QStringLiteral("Exec"));
    e.path = kv.value(QStringLiteral("Path"));
    e.terminal = boolean(QStringLiteral("Terminal"));
    e.noDisplay = boolean(QStringLiteral("NoDisplay")) || boolean(QStringLiteral("Hidden"));
    e.keywords = localized(QStringLiteral("Keywords")).split(QLatin1Char(';'), Qt::SkipEmptyParts);
    e.categories = kv.value(QStringLiteral("Categories")).split(QLatin1Char(';'), Qt::SkipEmptyParts);

    const QString tryExec = kv.value(QStringLiteral("TryExec"));
    if (!tryExec.isEmpty()) {
        const bool ok = tryExec.startsWith(QLatin1Char('/')) ? QFileInfo(tryExec).isExecutable()
                                                             : !QStandardPaths::findExecutable(tryExec).isEmpty();
        if (!ok) return std::nullopt;
    }
    // OnlyShowIn / NotShowIn
    const QString desktop = qEnvironmentVariable("XDG_CURRENT_DESKTOP", QStringLiteral("MIN"));
    const QStringList desktops = desktop.split(QLatin1Char(':'), Qt::SkipEmptyParts);
    const QStringList onlyShowIn = kv.value(QStringLiteral("OnlyShowIn")).split(QLatin1Char(';'), Qt::SkipEmptyParts);
    const QStringList notShowIn = kv.value(QStringLiteral("NotShowIn")).split(QLatin1Char(';'), Qt::SkipEmptyParts);
    auto intersects = [&](const QStringList &l) {
        for (const QString &d : desktops) if (l.contains(d)) return true;
        return false;
    };
    if (!onlyShowIn.isEmpty() && !intersects(onlyShowIn)) e.noDisplay = true;
    if (!notShowIn.isEmpty() && intersects(notShowIn)) e.noDisplay = true;

    if (e.name.isEmpty() || e.exec.isEmpty())
        return std::nullopt;
    return e;
}

QList<AppEntry> AppIndex::scan(const QStringList &dirs, const QString & /*currentDesktop*/)
{
    const QStringList locales = localeKeys();
    QHash<QString, AppEntry> byId; // 먼저 발견된 디렉터리가 우선 (XDG 규칙)
    QStringList order;
    for (const QString &dir : dirs) {
        QDirIterator it(dir, { QStringLiteral("*.desktop") }, QDir::Files, QDirIterator::Subdirectories);
        while (it.hasNext()) {
            const QString path = it.next();
            // 하위 디렉터리는 id에 '-'로 연결 (spec)
            QString id = QDir(dir).relativeFilePath(path);
            id.chop(8);
            id.replace(QLatin1Char('/'), QLatin1Char('-'));
            if (byId.contains(id))
                continue;
            auto e = parseDesktopFile(path, locales);
            if (!e) {
                byId.insert(id, AppEntry{}); // 상위 우선순위 디렉터리의 비활성 항목이 하위를 가린다
                continue;
            }
            e->id = id;
            byId.insert(id, *e);
            order << id;
        }
    }
    QList<AppEntry> result;
    for (const QString &id : order) {
        const AppEntry &e = byId.value(id);
        if (!e.noDisplay && !e.name.isEmpty())
            result.append(e);
    }
    return result;
}

QStringList AppIndex::execToArgs(const QString &exec)
{
    // Desktop Entry Spec: 공백 분리, 큰따옴표 인용, 필드 코드(%f %F %u %U %i %c %k %d %D %n %N %v %m) 제거
    QStringList args;
    QString cur;
    bool inQuote = false, hasToken = false;
    for (int i = 0; i < exec.size(); ++i) {
        const QChar c = exec.at(i);
        if (inQuote) {
            if (c == QLatin1Char('\\') && i + 1 < exec.size()) { cur += exec.at(++i); continue; }
            if (c == QLatin1Char('"')) { inQuote = false; continue; }
            if (c == QLatin1Char('%') && i + 1 < exec.size()) {
                const QChar code = exec.at(++i);
                if (code == QLatin1Char('%')) cur += code;
                continue;
            }
            cur += c;
            continue;
        }
        if (c == QLatin1Char('"')) { inQuote = true; hasToken = true; continue; }
        if (c.isSpace()) {
            if (hasToken) { args << cur; cur.clear(); hasToken = false; }
            continue;
        }
        if (c == QLatin1Char('%') && i + 1 < exec.size()) {
            const QChar code = exec.at(++i);
            if (code == QLatin1Char('%')) { cur += code; hasToken = true; }
            // 그 외 필드 코드는 버림 (인자 없이 실행)
            continue;
        }
        cur += c;
        hasToken = true;
    }
    if (hasToken) args << cur;
    args.removeAll(QString());
    return args;
}

QString AppIndex::terminalProgram() const
{
    const QString env = qEnvironmentVariable("MINOS_TERMINAL");
    if (!env.isEmpty()) return env;
    for (const char *cand : { "minos-terminal", "foot", "alacritty", "kitty", "weston-terminal", "xterm" })
        if (!QStandardPaths::findExecutable(QLatin1String(cand)).isEmpty())
            return QLatin1String(cand);
    return QStringLiteral("foot");
}

bool AppIndex::launch(int row)
{
    if (row < 0 || row >= m_visible.size())
        return false;
    return startEntry(m_all.at(m_visible.at(row)));
}

bool AppIndex::launchById(const QString &id)
{
    for (const AppEntry &e : m_all)
        if (e.id == id) return startEntry(e);
    emit launchFailed(id, QStringLiteral("not found"));
    return false;
}

bool AppIndex::launchCommand(const QString &command, bool inTerminal)
{
    AppEntry e;
    e.id = command;
    e.name = command;
    e.exec = command;
    e.terminal = inTerminal;
    return startEntry(e);
}

bool AppIndex::startEntry(const AppEntry &e)
{
    QStringList args = execToArgs(e.exec);
    if (args.isEmpty()) {
        emit launchFailed(e.id, QStringLiteral("empty Exec"));
        return false;
    }
    if (e.terminal)
        args.prepend(terminalProgram());
    const QString program = args.takeFirst();
    const QString workDir = e.path.isEmpty() ? QDir::homePath() : e.path;
    qint64 pid = 0;
    const bool ok = QProcess::startDetached(program, args, workDir, &pid);
    if (ok) {
        qCInfo(lcApps) << "launched" << e.id << program << args << "pid" << pid;
        emit launched(e.id);
    } else {
        qCWarning(lcApps) << "failed to launch" << e.id << program << args;
        emit launchFailed(e.id, QStringLiteral("could not start %1").arg(program));
    }
    return ok;
}
