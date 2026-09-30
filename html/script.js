(() => {
    const app = document.getElementById('app');
    const listEl = document.getElementById('list');
    const searchEl = document.getElementById('search');
    const countEl = document.getElementById('count');
    const viewLabel = document.getElementById('viewLabel');
    const navItems = document.querySelectorAll('.nav-item');

    let commands = [];
    let players = [];
    let favourites = {};
    let lists = {};
    let activeCategory = 'all';
    let selectedIndex = 0;
    let openRowId = null;

    const CATEGORY_LABELS = {
        all: 'ALL COMMANDS',
        players: 'PLAYER COMMANDS',
        economy: 'ECONOMY COMMANDS',
        vehicles: 'VEHICLE COMMANDS',
        teleport: 'TELEPORT COMMANDS',
        utility: 'UTILITY COMMANDS',
        user: 'USER COMMANDS'
    };

    function post(name, body) {
        return fetch(`https://${resourceName()}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(body || {})
        }).catch((err) => console.error('[codera-adminmenu] NUI callback failed:', name, err));
    }

    const nativeResourceName = (typeof window.GetParentResourceName === 'function')
        ? window.GetParentResourceName
        : null;

    function resourceName() {
        return nativeResourceName ? nativeResourceName() : (window.location.hostname || 'codera-adminmenu');
    }

    function starIcon() {
        return `<svg viewBox="0 0 576 512" fill="currentColor"><path d="M259.3 17.8L194 150.2 47.9 171.5c-26.2 3.8-36.7 36.1-17.7 54.6l105.7 103-25 145.5c-4.5 26.3 23.2 46 46.4 33.7L288 439.6l130.7 68.7c23.2 12.2 50.9-7.4 46.4-33.7l-25-145.5 105.7-103c19-18.5 8.5-50.8-17.7-54.6L382 150.2 316.7 17.8c-11.7-23.6-45.6-23.9-57.4 0z"/></svg>`;
    }

    function filteredCommands() {
        const q = searchEl.value.trim().toLowerCase();
        return commands
            .map((c, i) => ({ ...c, _i: i }))
            .filter(c => activeCategory === 'all' || c.category === activeCategory)
            .filter(c => !q || c.label.toLowerCase().includes(q) || c.desc.toLowerCase().includes(q));
    }

    function escapeHTML(value) {
        return String(value === undefined || value === null ? '' : value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    function optionParts(o) {
        if (typeof o === 'string' || typeof o === 'number') {
            return { value: String(o), label: String(o) };
        }
        const value = o.value !== undefined ? o.value : o.label;
        return { value: String(value), label: String(o.label !== undefined ? o.label : value) };
    }

    function fieldHTML(cmd) {
        let html = '';

        if (cmd.type === 'player') {
            html += `<div class="field">
                <label>Player${cmd.optionalPlayer ? ' (Optional)' : ''}</label>
                <select data-key="player">
                    <option value="">${cmd.optionalPlayer ? 'Yourself' : 'Select a player…'}</option>
                    ${players.map(p => `<option value="${escapeHTML(p.id)}">${escapeHTML(p.name)}</option>`).join('')}
                </select>
            </div>`;
        }

        if (cmd.type === 'select') {
            const options = lists[cmd.optionsKey] || [];
            html += `<div class="field">
                <label>${escapeHTML(cmd.selectLabel || 'Option')}</label>
                <select data-key="value">
                    ${options.map(o => {
                        const part = optionParts(o);
                        return `<option value="${escapeHTML(part.value)}">${escapeHTML(part.label)}</option>`;
                    }).join('')}
                </select>
            </div>`;
        }

        if (cmd.extra) {
            cmd.extra.forEach(f => {
                if (f.kind === 'select') {
                    const options = f.options || lists[f.optionsKey] || [];
                    html += `<div class="field">
                        <label>${escapeHTML(f.label)}</label>
                        <select data-key="${escapeHTML(f.key)}">
                            ${options.map(o => {
                                const part = optionParts(o);
                                return `<option value="${escapeHTML(part.value)}">${escapeHTML(part.label)}</option>`;
                            }).join('')}
                        </select>
                    </div>`;
                } else if (f.kind === 'datalist') {
                    const listId = `dl_${cmd.id}_${f.key}`;
                    const options = f.options || lists[f.optionsKey] || [];
                    html += `<div class="field">
                        <label>${escapeHTML(f.label)}</label>
                        <input type="text" list="${escapeHTML(listId)}" data-key="${escapeHTML(f.key)}" value="${escapeHTML(f.default)}" placeholder="${escapeHTML(f.placeholder)}" autocomplete="off" />
                        <datalist id="${escapeHTML(listId)}">
                            ${options.map(o => {
                                const part = optionParts(o);
                                return `<option value="${escapeHTML(part.value)}">${escapeHTML(part.label)}</option>`;
                            }).join('')}
                        </datalist>
                    </div>`;
                } else {
                    html += `<div class="field">
                        <label>${escapeHTML(f.label)}</label>
                        <input type="${f.kind === 'number' ? 'number' : 'text'}" data-key="${escapeHTML(f.key)}" value="${escapeHTML(f.default)}" placeholder="${escapeHTML(f.placeholder)}" autocomplete="off" />
                    </div>`;
                }
            });
        }

        return html;
    }

    function needsPanel(cmd) {
        return cmd.type === 'player' || cmd.type === 'select' || cmd.type === 'input' || !!cmd.extra;
    }

    function render() {
        const rows = filteredCommands();
        countEl.textContent = rows.length;
        viewLabel.textContent = CATEGORY_LABELS[activeCategory] || 'ALL COMMANDS';

        if (!rows.length) {
            listEl.innerHTML = `<div class="empty">No commands match your search.</div>`;
            return;
        }

        if (selectedIndex >= rows.length) selectedIndex = rows.length - 1;
        if (selectedIndex < 0) selectedIndex = 0;

        listEl.innerHTML = rows.map((cmd, idx) => {
            const isFav = !!favourites[cmd.id];
            const isSelected = idx === selectedIndex;
            const isOpen = openRowId === cmd.id;
            const panel = needsPanel(cmd) ? `<div class="row__panel">
                ${fieldHTML(cmd)}
                <button class="run-btn" data-run="${cmd.id}">Confirm</button>
            </div>` : '';

            return `<div class="row ${isSelected ? 'is-selected' : ''} ${isOpen ? 'is-open' : ''}" data-id="${cmd.id}" data-idx="${idx}">
                <div class="row__head" data-toggle="${cmd.id}">
                    <span class="row__star ${isFav ? 'is-fav' : ''}" data-fav="${cmd.id}">${starIcon()}</span>
                    <div class="row__text">
                        <div class="row__title">${cmd.label}</div>
                        <div class="row__desc">${cmd.desc}</div>
                    </div>
                    ${panel ? `<span class="row__chevron"><svg viewBox="0 0 448 512" fill="currentColor"><path d="M207.029 381.476L12.686 187.132c-9.373-9.373-9.373-24.569 0-33.941l22.667-22.667c9.357-9.357 24.522-9.375 33.901-.04L224 284.505l154.745-154.021c9.379-9.335 24.544-9.317 33.901.04l22.667 22.667c9.373 9.373 9.373 24.569 0 33.941L240.971 381.476c-9.373 9.372-24.569 9.372-33.942 0z"/></svg></span>` : ''}
                </div>
                ${panel}
            </div>`;
        }).join('');

        listEl.querySelectorAll('[data-toggle]').forEach(el => {
            el.addEventListener('click', () => onRowHeadClick(el.getAttribute('data-toggle')));
        });
        listEl.querySelectorAll('[data-fav]').forEach(el => {
            el.addEventListener('click', (e) => {
                e.stopPropagation();
                toggleFavourite(el.getAttribute('data-fav'));
            });
        });
        listEl.querySelectorAll('[data-run]').forEach(el => {
            el.addEventListener('click', (e) => {
                e.stopPropagation();
                runCommand(el.getAttribute('data-run'));
            });
        });
    }

    function onRowHeadClick(id) {
        const cmd = commands.find(c => c.id === id);
        if (!cmd) return;

        if (!needsPanel(cmd)) {
            runCommand(id);
            return;
        }

        openRowId = openRowId === id ? null : id;
        render();
    }

    function collectPayload(id) {
        const rowEl = listEl.querySelector(`.row[data-id="${id}"]`);
        const payload = {};
        if (!rowEl) return payload;
        rowEl.querySelectorAll('[data-key]').forEach(input => {
            payload[input.getAttribute('data-key')] = input.value;
        });
        return payload;
    }

    function runCommand(id) {
        const payload = collectPayload(id);
        post('runCommand', { id, payload });
        openRowId = null;
        render();
    }

    function toggleFavourite(id) {
        favourites[id] = !favourites[id];
        post('toggleFavourite', { id });
        render();
    }

    navItems.forEach(btn => {
        btn.addEventListener('click', () => {
            navItems.forEach(b => b.classList.remove('is-active'));
            btn.classList.add('is-active');
            activeCategory = btn.getAttribute('data-cat');
            selectedIndex = 0;
            render();
        });
    });

    searchEl.addEventListener('input', () => {
        selectedIndex = 0;
        render();
    });

    function closeMenu() {
        app.classList.add('hidden');
        post('close').then(() => {}, () => {});
        setTimeout(() => post('close'), 150);
    }

    document.addEventListener('keydown', (e) => {
        if (app.classList.contains('hidden')) return;

        if (e.key === 'Escape') {
            closeMenu();
        } else if (e.key === 'ArrowDown') {
            e.preventDefault();
            selectedIndex++;
            render();
        } else if (e.key === 'ArrowUp') {
            e.preventDefault();
            selectedIndex--;
            render();
        } else if (e.key === 'Enter') {
            const rows = filteredCommands();
            const cmd = rows[selectedIndex];
            if (cmd) onRowHeadClick(cmd.id);
        } else if (e.key.toLowerCase() === 'f') {
            const rows = filteredCommands();
            const cmd = rows[selectedIndex];
            if (cmd) toggleFavourite(cmd.id);
        } else if (e.key.toLowerCase() === 'q') {
            const cats = Array.from(navItems).map(b => b.getAttribute('data-cat'));
            const next = cats[(cats.indexOf(activeCategory) + 1) % cats.length];
            document.querySelector(`.nav-item[data-cat="${next}"]`).click();
        }
    });

    window.addEventListener('message', (e) => {
        const data = e.data;
        if (data.action === 'open') {
            commands = data.commands || [];
            players = data.players || [];
            favourites = data.favourites || {};
            lists = data.lists || {};
            activeCategory = 'all';
            selectedIndex = 0;
            openRowId = null;
            searchEl.value = '';
            navItems.forEach(b => b.classList.remove('is-active'));
            document.querySelector('.nav-item[data-cat="all"]').classList.add('is-active');
            app.classList.remove('hidden');
            render();
            searchEl.focus();
        } else if (data.action === 'copy') {
            const area = document.createElement('textarea');
            area.value = data.text || '';
            area.style.position = 'fixed';
            area.style.opacity = '0';
            document.body.appendChild(area);
            area.select();
            document.execCommand('copy');
            area.remove();
        } else if (data.action === 'close') {
            app.classList.add('hidden');
        }
    });
})();
