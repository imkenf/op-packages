'use strict';
'require baseclass';
'require rpc';

const callMwan3Status = rpc.declare({
	object: 'mwan3',
	method: 'status',
	params: ['section'],
	expect: {  },
});

document.querySelector('head').appendChild(E('link', {
	'rel': 'stylesheet',
	'type': 'text/css',
	'href': L.resource('view/mwan3/mwan3.css')
}));

function renderMwan3Status(status) {
	if (!status.interfaces)
		return '<strong>%h</strong>'.format(_('No MWAN interfaces found'));

	var statusview = '';
	for ( var iface in status.interfaces) {
		var state = '';
		var css = '';
		var time = '';
		var tname = '';
		switch (status.interfaces[iface].status) {
			case 'online':
				state = _('Online');
				css = 'success';
				time = '%t'.format(status.interfaces[iface].online);
				tname = _('Uptime');
				break;
			case 'offline':
				state = _('Offline');
				css = 'danger';
				time = '%t'.format(status.interfaces[iface].offline);
				tname = _('Downtime');
				break;
			case 'notracking':
				state = _('No Tracking');
				if ((status.interfaces[iface].uptime) > 0) {
					css = 'success';
					time = '%t'.format(status.interfaces[iface].uptime);
					tname = _('Uptime');
				}
				else {
					css = 'warning';
					time = '';
					tname = '';
				}
				break;
			default:
				state = _('Disabled');
				css = 'warning';
				time = '';
				tname = '';
				break;
		}

		var progressWidth = 0;
		var timeIcon = '';
		if (time && status.interfaces[iface].status === 'online') {
			var dayMatch = time.match(/(\d+)d/);
			var days = dayMatch ? parseInt(dayMatch[1]) : 0;
			progressWidth = Math.min((days / 30) * 100, 100);
			timeIcon = '<svg class="mwan3-time-icon" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>';
		} else if (time) {
			var dayMatch2 = time.match(/(\d+)d/);
			var hourMatch = time.match(/(\d+)h/);
			var days2 = dayMatch2 ? parseInt(dayMatch2[1]) : 0;
			var hours = hourMatch ? parseInt(hourMatch[1]) : 0;
			progressWidth = Math.min(((days2 * 24 + hours) / (7 * 24)) * 100, 100);
			timeIcon = '<svg class="mwan3-time-icon" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm5 11H7v-2h10v2z"/></svg>';
		}

		statusview += '<div class="alert-message %h">'.format(css);
		statusview += '<div class="mwan3-interface-name">%h</div>'.format(iface.toUpperCase());
		statusview += '<div class="mwan3-status-text">%h</div>'.format(state);

		if (time) {
			statusview += '<div class="mwan3-time-info">';
			statusview += '<div class="mwan3-time-line">';
			statusview += '<div class="mwan3-time-label">%s %h</div>'.format(timeIcon, tname);
			statusview += '<div class="mwan3-time-amount">%h</div>'.format(time);
			statusview += '</div>';
			statusview += '<div class="mwan3-time-progress">';
			statusview += '<div class="mwan3-time-progress-bar" style="width: %d%%"></div>'.format(progressWidth);
			statusview += '</div>';
			statusview += '</div>';
		}

		statusview += '</div>';
	}

	return statusview;
}

return baseclass.extend({
	title: _('MultiWAN Manager'),

	load: function() {
		return Promise.all([
			callMwan3Status("interfaces"),
		]);
	},

	render: function (result) {
		if (!result[0].interfaces)
			return null;

		var container = E('div', { 'id': 'mwan3-service-status' });
		container.innerHTML = renderMwan3Status(result[0]);
		return container;
	}
});
