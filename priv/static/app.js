// UrbanWay Frontend App

const API = '/api';

// === Utils ===
async function api(method, path, body = null) {
  const opts = {
    method,
    headers: { 'Content-Type': 'application/json' }
  };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(API + path, opts);
  return res.json();
}

function $(sel) { return document.querySelector(sel); }
function $$(sel) { return document.querySelectorAll(sel); }


// === Tab Navigation ===
$$('.tab').forEach(tab => {
  tab.addEventListener('click', () => {
    $$('.tab').forEach(t => t.classList.remove('active'));
    $$('.tab-content').forEach(c => c.classList.remove('active'));
    tab.classList.add('active');
    $(`#${tab.dataset.tab}`).classList.add('active');
    
    // Load data for active tab
    loadTabData(tab.dataset.tab);
  });
});

$$('.sub-tab').forEach(tab => {
  tab.addEventListener('click', () => {
    $$('.sub-tab').forEach(t => t.classList.remove('active'));
    $$('.sub-tab-content').forEach(c => c.classList.remove('active'));
    tab.classList.add('active');
    $(`#rel-${tab.dataset.subtab}`).classList.add('active');
    
    loadRelationshipData(tab.dataset.subtab);
  });
});

function loadTabData(tabName) {
  switch (tabName) {
    case 'pathfinder': loadLocationsForPathfinder(); break;
    case 'stops': loadStops(); break;
    case 'locations': loadLocations(); break;
    case 'routes': loadRoutes(); break;
    case 'relationships': loadRelationshipData('next'); break;
    case 'map': loadGraph(); break;
  }
}

// === PATHFINDER ===
async function loadLocationsForPathfinder() {
  const data = await api('GET', '/locations');
  const locs = data.locations || [];
  
  const fromSel = $('#from-location');
  const toSel = $('#to-location');
  
  const fromValue = fromSel.value;
  const toValue = toSel.value;
  
  const options = locs.map(l => `<option value="${l.id}">${l.name}</option>`).join('');
  fromSel.innerHTML = '<option value="">Выберите локацию</option>' + options;
  toSel.innerHTML = '<option value="">Выберите локацию</option>' + options;
  
  fromSel.value = fromValue;
  toSel.value = toValue;
}

$('#find-path').addEventListener('click', async () => {
  const fromId = $('#from-location').value;
  const toId = $('#to-location').value;
  
  if (!fromId || !toId) {
    alert('Выберите обе локации');
    return;
  }
  
  if (fromId === toId) {
    alert('Выберите разные локации');
    return;
  }
  
  const btn = $('#find-path');
  btn.disabled = true;
  btn.textContent = 'Поиск...';
  
  try {
    const data = await api('GET', `/pathfinder?from_location=${fromId}&to_location=${toId}`);
    displayPath(data);
  } catch (e) {
    $('#path-result').innerHTML = '<div class="path-error">Ошибка при поиске маршрута</div>';
    $('#path-result').classList.remove('hidden');
  } finally {
    btn.disabled = false;
    btn.textContent = 'Найти маршрут';
  }
});

function displayPath(data) {
  const result = $('#path-result');
  
  if (data.error || !data.path) {
    result.innerHTML = `<div class="path-error">❌ ${data.error || 'Маршрут не найден'}</div>`;
    result.classList.remove('hidden');
    return;
  }
  
  const path = data.path;
  let html = `<h3>Маршрут: ${path.from_location.name} → ${path.to_location.name}</h3>`;
  
  if (!path.steps || path.steps.length === 0) {
    html += '<div class="path-error">Маршрут не найден</div>';
  } else {
    path.steps.forEach(step => {
      html += renderStep(step);
    });
  }
  
  result.innerHTML = html;
  result.classList.remove('hidden');
}

function renderStep(step) {
  switch (step.type) {
    case 'walk_to_stop':
      return `
        <div class="path-step walk">
          <span class="step-icon">🚶</span>
          <div class="step-info">
            <div class="step-title">Идите до остановки</div>
            <div class="step-detail">🚏 ${step.stop.name}</div>
          </div>
        </div>`;
    case 'ride':
      return `
        <div class="path-step">
          <span class="step-icon">🚌</span>
          <div class="step-info">
            <div class="step-title">${step.route}</div>
            <div class="step-detail">${step.count} остановок: ${step.stops.join(' → ')}</div>
          </div>
        </div>`;
    case 'transfer':
      return `
        <div class="path-step transfer">
          <span class="step-icon">🔄</span>
          <div class="step-info">
            <div class="step-title">Пересадка</div>
            <div class="step-detail">${step.from_stop} → ${step.to_stop}</div>
          </div>
        </div>`;
    case 'walk_to_location':
      return `
        <div class="path-step walk">
          <span class="step-icon">🚶</span>
          <div class="step-info">
            <div class="step-title">Идите до локации</div>
            <div class="step-detail">📍 ${step.location.name}</div>
          </div>
        </div>`;
    default:
      return '';
  }
}

// === STOPS ===
async function loadStops() {
  const params = new URLSearchParams();
  const name = $('#stops-filter-name').value;
  const latMin = $('#stops-filter-lat-min').value;
  const latMax = $('#stops-filter-lat-max').value;
  const lonMin = $('#stops-filter-lon-min').value;
  const lonMax = $('#stops-filter-lon-max').value;
  const sort = $('#stops-sort').value;
  const order = $('#stops-order').value;
  const limit = $('#stops-limit').value;
  
  if (name) params.set('name', name);
  if (latMin) params.set('lat_min', latMin);
  if (latMax) params.set('lat_max', latMax);
  if (lonMin) params.set('lon_min', lonMin);
  if (lonMax) params.set('lon_max', lonMax);
  if (sort) params.set('sort', sort);
  if (order) params.set('order', order);
  if (limit) params.set('limit', limit);
  
  const query = params.toString() ? '?' + params.toString() : '';
  const data = await api('GET', '/stops' + query);
  const stops = data.stops || [];
  
  const tbody = $('#stops-table tbody');
  if (stops.length === 0) {
    tbody.innerHTML = '<tr><td colspan="5" class="empty-state">Нет остановок</td></tr>';
    return;
  }
  
  tbody.innerHTML = stops.map(s => `
    <tr>
      <td>${s.name}</td>
      <td>${s.latitude}</td>
      <td>${s.longitude}</td>
      <td><button class="edit-btn" data-id="${s.id}" data-name="${s.name}" data-lat="${s.latitude}" data-lon="${s.longitude}">✏️</button></td>
      <td><button class="delete-btn" data-id="${s.id}">🗑</button></td>
    </tr>
  `).join('');
  
  tbody.querySelectorAll('.edit-btn').forEach(btn => {
    btn.addEventListener('click', () => openEditStopModal(btn.dataset));
  });
  tbody.querySelectorAll('.delete-btn').forEach(btn => {
    btn.addEventListener('click', () => deleteStop(btn.dataset.id));
  });
}

$('#stops-apply-filter').addEventListener('click', loadStops);

$('#add-stop').addEventListener('click', async () => {
  const name = $('#stop-name').value.trim();
  const lat = parseFloat($('#stop-lat').value);
  const lon = parseFloat($('#stop-lon').value);
  
  if (!name || isNaN(lat) || isNaN(lon)) {
    alert('Заполните все поля');
    return;
  }
  
  await api('POST', '/stops', { name, latitude: lat, longitude: lon });
  $('#stop-name').value = '';
  $('#stop-lat').value = '';
  $('#stop-lon').value = '';
  loadStops();
});

async function deleteStop(id) {
  if (!confirm('Удалить остановку?')) return;
  await api('DELETE', `/stops/${id}`);
  loadStops();
}

// === LOCATIONS ===
async function loadLocations() {
  const params = new URLSearchParams();
  const name = $('#locations-filter-name').value;
  const sort = $('#locations-sort').value;
  const order = $('#locations-order').value;
  const limit = $('#locations-limit').value;
  
  if (name) params.set('name', name);
  if (sort) params.set('sort', sort);
  if (order) params.set('order', order);
  if (limit) params.set('limit', limit);
  
  const query = params.toString() ? '?' + params.toString() : '';
  const data = await api('GET', '/locations' + query);
  const locs = data.locations || [];
  
  const tbody = $('#locations-table tbody');
  if (locs.length === 0) {
    tbody.innerHTML = '<tr><td colspan="3" class="empty-state">Нет локаций</td></tr>';
    return;
  }
  
  tbody.innerHTML = locs.map(l => `
    <tr>
      <td>${l.name}</td>
      <td><button class="edit-btn" data-id="${l.id}" data-name="${l.name}">✏️</button></td>
      <td><button class="delete-btn" data-id="${l.id}">🗑</button></td>
    </tr>
  `).join('');
  
  tbody.querySelectorAll('.edit-btn').forEach(btn => {
    btn.addEventListener('click', () => openEditLocationModal(btn.dataset));
  });
  tbody.querySelectorAll('.delete-btn').forEach(btn => {
    btn.addEventListener('click', () => deleteLocation(btn.dataset.id));
  });
}

$('#locations-apply-filter').addEventListener('click', loadLocations);

$('#add-location').addEventListener('click', async () => {
  const name = $('#location-name').value.trim();
  if (!name) {
    alert('Введите название');
    return;
  }
  
  await api('POST', '/locations', { name });
  $('#location-name').value = '';
  loadLocations();
});

async function deleteLocation(id) {
  if (!confirm('Удалить локацию?')) return;
  await api('DELETE', `/locations/${id}`);
  loadLocations();
}

// === ROUTES ===
async function loadRoutes() {
  const params = new URLSearchParams();
  const name = $('#routes-filter-name').value;
  const sort = $('#routes-sort').value;
  const order = $('#routes-order').value;
  const limit = $('#routes-limit').value;
  
  if (name) params.set('name', name);
  if (sort) params.set('sort', sort);
  if (order) params.set('order', order);
  if (limit) params.set('limit', limit);
  
  const query = params.toString() ? '?' + params.toString() : '';
  const data = await api('GET', '/routes' + query);
  const routes = data.routes || [];
  
  const tbody = $('#routes-table tbody');
  if (routes.length === 0) {
    tbody.innerHTML = '<tr><td colspan="4" class="empty-state">Нет маршрутов</td></tr>';
    return;
  }
  
  tbody.innerHTML = routes.map(r => `
    <tr>
      <td>${r.name}</td>
      <td><button class="show-btn" data-name="${r.name}">Показать</button></td>
      <td><button class="edit-btn" data-id="${r.id}" data-name="${r.name}">✏️</button></td>
      <td><button class="delete-btn" data-id="${r.id}">🗑</button></td>
    </tr>
  `).join('');
  
  tbody.querySelectorAll('.edit-btn').forEach(btn => {
    btn.addEventListener('click', () => openEditRouteModal(btn.dataset));
  });
  tbody.querySelectorAll('.delete-btn').forEach(btn => {
    btn.addEventListener('click', () => deleteRoute(btn.dataset.id));
  });
  
  tbody.querySelectorAll('.show-btn').forEach(btn => {
    btn.addEventListener('click', () => showRouteStops(btn.dataset.name));
  });
}

$('#routes-apply-filter').addEventListener('click', loadRoutes);

$('#add-route').addEventListener('click', async () => {
  const name = $('#route-name').value.trim();
  if (!name) {
    alert('Введите название');
    return;
  }
  
  await api('POST', '/routes', { name });
  $('#route-name').value = '';
  cachedRoutes = []; // сбросить кэш
  loadRoutes();
});

async function deleteRoute(id) {
  if (!confirm('Удалить маршрут?')) return;
  await api('DELETE', `/routes/${id}`);
  cachedRoutes = []; // сбросить кэш
  loadRoutes();
}

async function showRouteStops(routeName) {
  const data = await api('GET', `/routes/${encodeURIComponent(routeName)}/stops`);
  const stops = data.stops || [];
  
  $('#modal-route-name').textContent = routeName;
  
  if (stops.length === 0) {
    $('#modal-stops-list').innerHTML = '<li>Нет остановок</li>';
  } else {
    $('#modal-stops-list').innerHTML = stops.map(s => `<li>🚏 ${s.name}</li>`).join('');
  }
  
  $('#route-stops-modal').classList.remove('hidden');
}

// Modal close handlers moved to EDIT MODALS section

// === RELATIONSHIPS ===
async function loadRelationshipData(type) {
  await loadStopsForSelects();
  await loadLocationsForSelects();
  await loadRoutesForSelects();
  
  switch (type) {
    case 'next': await loadNextRelationships(); break;
    case 'transfers': await loadTransfers(); break;
    case 'nearby': await loadNearby(); break;
  }
}

// Кэши сбрасываются при фокусе на селектах
let cachedStops = [];
let cachedLocations = [];
let cachedRoutes = [];

// Обновлять селекты при клике/фокусе
document.addEventListener('focus', async (e) => {
  const id = e.target.id;
  if (['next-from-stop', 'next-to-stop', 'transfer-from-stop', 'transfer-to-stop', 'nearby-stop'].includes(id)) {
    cachedStops = [];
    await loadStopsForSelects();
  }
  if (['nearby-location', 'nearby-filter-location', 'from-location', 'to-location'].includes(id)) {
    cachedLocations = [];
    await loadLocationsForSelects();
    if (['from-location', 'to-location'].includes(id)) {
      await loadLocationsForPathfinder();
    }
  }
  if (id === 'next-route') {
    cachedRoutes = [];
    await loadRoutesForSelects();
  }
}, true);

async function loadStopsForSelects() {
  if (cachedStops.length === 0) {
    const data = await api('GET', '/stops');
    cachedStops = data.stops || [];
  }
  
  const options = cachedStops.map(s => `<option value="${s.id}">${s.name}</option>`).join('');
  
  ['#next-from-stop', '#next-to-stop', '#transfer-from-stop', '#transfer-to-stop', '#nearby-stop'].forEach(sel => {
    const el = $(sel);
    if (el) {
      const currentValue = el.value; // Сохраняем текущее значение
      el.innerHTML = `<option value="">${el.options[0]?.text || 'Остановка...'}</option>` + options;
      el.value = currentValue; // Восстанавливаем выбранное значение
    }
  });
}

async function loadLocationsForSelects() {
  if (cachedLocations.length === 0) {
    const data = await api('GET', '/locations');
    cachedLocations = data.locations || [];
  }
  
  const options = cachedLocations.map(l => `<option value="${l.id}">${l.name}</option>`).join('');
  
  ['#nearby-location', '#nearby-filter-location'].forEach(sel => {
    const el = $(sel);
    if (el) {
      const currentValue = el.value;
      const placeholder = sel === '#nearby-filter-location' ? 'Все локации' : 'Локация...';
      el.innerHTML = `<option value="">${placeholder}</option>` + options;
      el.value = currentValue;
    }
  });
}

async function loadRoutesForSelects() {
  if (cachedRoutes.length === 0) {
    const data = await api('GET', '/routes');
    cachedRoutes = data.routes || [];
  }
  
  const options = cachedRoutes.map(r => `<option value="${r.name}">${r.name}</option>`).join('');
  const el = $('#next-route');
  if (el) {
    const currentValue = el.value;
    el.innerHTML = '<option value="">Маршрут...</option>' + options;
    el.value = currentValue;
  }
}

// NEXT
async function loadNextRelationships() {
  const route = $('#next-filter-route').value;
  const query = route ? `?route=${encodeURIComponent(route)}` : '';
  const data = await api('GET', '/relationships/next' + query);
  const rels = data.next || [];
  
  const tbody = $('#next-table tbody');
  if (rels.length === 0) {
    tbody.innerHTML = '<tr><td colspan="4" class="empty-state">Нет связей</td></tr>';
    return;
  }
  
  tbody.innerHTML = rels.map(r => `
    <tr>
      <td>${r.from_name}</td>
      <td>${r.to_name}</td>
      <td>${r.route}</td>
      <td><button class="delete-btn" data-from="${r.from_id}" data-to="${r.to_id}" data-route="${r.route}">🗑</button></td>
    </tr>
  `).join('');
  
  tbody.querySelectorAll('.delete-btn').forEach(btn => {
    btn.addEventListener('click', () => deleteNext(btn.dataset.from, btn.dataset.to, btn.dataset.route));
  });
}

$('#next-apply-filter').addEventListener('click', loadNextRelationships);

$('#add-next').addEventListener('click', async () => {
  const fromId = $('#next-from-stop').value;
  const toId = $('#next-to-stop').value;
  const route = $('#next-route').value;
  
  if (!fromId || !toId || !route) {
    alert('Заполните все поля');
    return;
  }
  
  await api('POST', '/relationships/next', { from_id: fromId, to_id: toId, route });
  $('#next-from-stop').value = '';
  $('#next-to-stop').value = '';
  $('#next-route').value = '';
  loadNextRelationships();
});

async function deleteNext(fromId, toId, route) {
  if (!confirm('Удалить связь?')) return;
  await api('DELETE', '/relationships/next', { from_id: fromId, to_id: toId, route });
  loadNextRelationships();
}

// TRANSFERS
async function loadTransfers() {
  const data = await api('GET', '/relationships/transfers');
  const rels = data.transfers || [];
  
  const tbody = $('#transfers-table tbody');
  if (rels.length === 0) {
    tbody.innerHTML = '<tr><td colspan="3" class="empty-state">Нет пересадок</td></tr>';
    return;
  }
  
  tbody.innerHTML = rels.map(r => `
    <tr>
      <td>${r.from_name}</td>
      <td>${r.to_name}</td>
      <td><button class="delete-btn" data-from="${r.from_id}" data-to="${r.to_id}">🗑</button></td>
    </tr>
  `).join('');
  
  tbody.querySelectorAll('.delete-btn').forEach(btn => {
    btn.addEventListener('click', () => deleteTransfer(btn.dataset.from, btn.dataset.to));
  });
}

$('#add-transfer').addEventListener('click', async () => {
  const fromId = $('#transfer-from-stop').value;
  const toId = $('#transfer-to-stop').value;
  
  if (!fromId || !toId) {
    alert('Выберите обе остановки');
    return;
  }
  
  await api('POST', '/relationships/transfers', { from_id: fromId, to_id: toId });
  $('#transfer-from-stop').value = '';
  $('#transfer-to-stop').value = '';
  loadTransfers();
});

async function deleteTransfer(fromId, toId) {
  if (!confirm('Удалить пересадку?')) return;
  await api('DELETE', '/relationships/transfers', { from_id: fromId, to_id: toId });
  loadTransfers();
}

// NEARBY
async function loadNearby() {
  const locId = $('#nearby-filter-location').value;
  const query = locId ? `?location_id=${locId}` : '';
  const data = await api('GET', '/relationships/nearby' + query);
  const rels = data.relationships || [];
  
  const tbody = $('#nearby-table tbody');
  if (rels.length === 0) {
    tbody.innerHTML = '<tr><td colspan="3" class="empty-state">Нет связей</td></tr>';
    return;
  }
  
  tbody.innerHTML = rels.map(r => `
    <tr>
      <td>${r.location_name}</td>
      <td>${r.stop_name}</td>
      <td><button class="delete-btn" data-loc="${r.location_id}" data-stop="${r.stop_id}">🗑</button></td>
    </tr>
  `).join('');
  
  tbody.querySelectorAll('.delete-btn').forEach(btn => {
    btn.addEventListener('click', () => deleteNearby(btn.dataset.loc, btn.dataset.stop));
  });
}

$('#nearby-apply-filter').addEventListener('click', loadNearby);

$('#add-nearby').addEventListener('click', async () => {
  const locId = $('#nearby-location').value;
  const stopId = $('#nearby-stop').value;
  
  if (!locId || !stopId) {
    alert('Выберите локацию и остановку');
    return;
  }
  
  await api('POST', '/relationships/nearby', { location_id: locId, stop_id: stopId });
  $('#nearby-location').value = '';
  $('#nearby-stop').value = '';
  loadNearby();
});

async function deleteNearby(locId, stopId) {
  if (!confirm('Удалить связь?')) return;
  await api('DELETE', '/relationships/nearby', { location_id: locId, stop_id: stopId });
  loadNearby();
}

// === EDIT MODALS ===

// Stop Edit
function openEditStopModal(data) {
  $('#edit-stop-id').value = data.id;
  $('#edit-stop-name').value = data.name;
  $('#edit-stop-lat').value = data.lat;
  $('#edit-stop-lon').value = data.lon;
  $('#edit-stop-modal').classList.remove('hidden');
}

$('#save-stop').addEventListener('click', async () => {
  const id = $('#edit-stop-id').value;
  const name = $('#edit-stop-name').value.trim();
  const latitude = parseFloat($('#edit-stop-lat').value);
  const longitude = parseFloat($('#edit-stop-lon').value);
  
  if (!name || isNaN(latitude) || isNaN(longitude)) {
    alert('Заполните все поля корректно');
    return;
  }
  
  await api('PUT', `/stops/${id}`, { name, latitude, longitude });
  $('#edit-stop-modal').classList.add('hidden');
  cachedStops = [];
  loadStops();
});

// Location Edit
function openEditLocationModal(data) {
  $('#edit-location-id').value = data.id;
  $('#edit-location-name').value = data.name;
  $('#edit-location-modal').classList.remove('hidden');
}

$('#save-location').addEventListener('click', async () => {
  const id = $('#edit-location-id').value;
  const name = $('#edit-location-name').value.trim();
  
  if (!name) {
    alert('Введите название');
    return;
  }
  
  await api('PUT', `/locations/${id}`, { name });
  $('#edit-location-modal').classList.add('hidden');
  cachedLocations = [];
  loadLocations();
});

// Route Edit
function openEditRouteModal(data) {
  $('#edit-route-id').value = data.id;
  $('#edit-route-name').value = data.name;
  $('#edit-route-modal').classList.remove('hidden');
}

$('#save-route').addEventListener('click', async () => {
  const id = $('#edit-route-id').value;
  const name = $('#edit-route-name').value.trim();
  
  if (!name) {
    alert('Введите название');
    return;
  }
  
  await api('PUT', `/routes/${id}`, { name });
  $('#edit-route-modal').classList.add('hidden');
  cachedRoutes = [];
  loadRoutes();
});

// Close modals
$$('.close-modal').forEach(btn => {
  btn.addEventListener('click', () => {
    $$('.modal').forEach(m => m.classList.add('hidden'));
  });
});

$$('.modal').forEach(modal => {
  modal.addEventListener('click', (e) => {
    if (e.target === modal) {
      modal.classList.add('hidden');
    }
  });
});

// === GRAPH VISUALIZATION ===
let graphNetwork = null;

async function loadGraph() {
  const data = await api('GET', '/graph');
  if (!data.graph) return;
  
  const graph = data.graph;
  const nodes = [];
  const edges = [];
  
  // Add stop nodes (blue)
  graph.stops.forEach(s => {
    nodes.push({
      id: 's_' + s.id,
      label: s.name,
      color: { background: '#4a9eff', border: '#2a7edf' },
      shape: 'dot',
      size: 20,
      font: { color: '#e8e8e8' },
      title: `Остановка: ${s.name}\nШирота: ${s.lat}\nДолгота: ${s.lon}`
    });
  });
  
  // Add location nodes (green)
  graph.locations.forEach(l => {
    nodes.push({
      id: 'l_' + l.id,
      label: l.name,
      color: { background: '#00d4aa', border: '#00b490' },
      shape: 'diamond',
      size: 25,
      font: { color: '#e8e8e8' },
      title: `Локация: ${l.name}`
    });
  });
  
  // Add NEXT edges (dark gray with route label) - длинные связи
  graph.next_edges.forEach(e => {
    edges.push({
      from: 's_' + e.from,
      to: 's_' + e.to,
      color: { color: '#666', highlight: '#888' },
      arrows: 'to',
      label: e.route,
      font: { 
        color: '#ffffff', 
        size: 21,
        strokeWidth: 0
      },
      title: `NEXT: ${e.route}`,
      length: 250
    });
  });
  
  // Add TRANSFER edges (orange dashed) - средние связи
  graph.transfer_edges.forEach(e => {
    edges.push({
      from: 's_' + e.from,
      to: 's_' + e.to,
      color: { color: '#ffa502', highlight: '#ffb833' },
      arrows: 'to',
      dashes: true,
      width: 2,
      title: 'TRANSFER',
      length: 200
    });
  });
  
  // Add NEARBY edges (thin gray) - короткие связи, локация рядом с остановкой
  graph.nearby_edges.forEach(e => {
    edges.push({
      from: 'l_' + e.location,
      to: 's_' + e.stop,
      color: { color: '#555', highlight: '#777' },
      width: 1,
      dashes: [2, 4],
      title: 'NEARBY',
      length: 60
    });
  });
  
  const container = document.getElementById('graph-container');
  const visData = {
    nodes: new vis.DataSet(nodes),
    edges: new vis.DataSet(edges)
  };
  
  const options = {
    nodes: {
      font: { size: 14 },
      fixed: { x: false, y: false }
    },
    edges: {
      font: { size: 10, align: 'middle' },
      smooth: { type: 'continuous' }
    },
    physics: {
      enabled: true,
      solver: 'barnesHut',
      barnesHut: {
        gravitationalConstant: -3000,
        centralGravity: 0.1,
        springLength: 200,
        springConstant: 0.02,
        damping: 0.3
      },
      stabilization: { 
        enabled: true,
        iterations: 200,
        fit: true
      }
    },
    interaction: {
      hover: true,
      tooltipDelay: 100,
      dragNodes: true,
      dragView: true,
      zoomView: true
    }
  };
  
  if (graphNetwork) {
    graphNetwork.destroy();
  }
  
  graphNetwork = new vis.Network(container, visData, options);
  
  // После стабилизации отключаем физику, чтобы узлы оставались на месте
  graphNetwork.on('stabilizationIterationsDone', () => {
    graphNetwork.setOptions({ physics: { enabled: false } });
  });
}

// === INIT ===
document.addEventListener('DOMContentLoaded', () => {
  loadLocationsForPathfinder();
});

