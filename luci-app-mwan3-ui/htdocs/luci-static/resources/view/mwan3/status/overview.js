'use strict';
'require poll';
'require view';
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
				css = 'success';
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

		// 计算时间进度百分比 (简单示例，基于天数)
		var progressWidth = 0;
		var timeIcon = '';
		if (time && status.interfaces[iface].status === 'online') {
			// 提取天数来计算进度 (最大30天为100%)
			var dayMatch = time.match(/(\d+)d/);
			var days = dayMatch ? parseInt(dayMatch[1]) : 0;
			progressWidth = Math.min((days / 30) * 100, 100);
			timeIcon = '<svg class="mwan3-time-icon" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>';
		} else if (time) {
			// 离线时间，显示为红色进度
			var dayMatch = time.match(/(\d+)d/);
			var hourMatch = time.match(/(\d+)h/);
			var days = dayMatch ? parseInt(dayMatch[1]) : 0;
			var hours = hourMatch ? parseInt(hourMatch[1]) : 0;
			progressWidth = Math.min(((days * 24 + hours) / (7 * 24)) * 100, 100); // 最大7天
			timeIcon = '<svg class="mwan3-time-icon" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm5 11H7v-2h10v2z"/></svg>';
		}

		statusview += '<div class="alert-message %h">'.format(css);
		statusview += '<div class="mwan3-interface-name">%h</div>'.format(iface.toUpperCase());
		statusview += '<div class="mwan3-status-text">%h</div>'.format(state);

		if (time) {
			statusview += '<div class="mwan3-time-info">';
			statusview += '<div class="mwan3-time-label">%h %h</div>'.format(timeIcon, tname);
			statusview += '<div class="mwan3-time-progress">';
			statusview += '<div class="mwan3-time-progress-bar" style="width: %d%%"></div>'.format(progressWidth);
			statusview += '</div>';
			statusview += '<div class="mwan3-time-value">';
			statusview += '<span>%h</span>'.format(time);
			statusview += '<span>%d%%</span>'.format(Math.round(progressWidth));
			statusview += '</div>';
			statusview += '</div>';
		}

		statusview += '</div>';
	}

	return statusview;
}

return view.extend({
	load: function() {
		return Promise.all([
			callMwan3Status("interfaces"),
		]);
	},

	render: function (data) {
		poll.add(function() {
			return callMwan3Status("interfaces").then(function(result) {
				var view = document.getElementById('mwan3-service-status');
				view.innerHTML = renderMwan3Status(result);
			});
		});

		return E('div', { class: 'cbi-map' }, [
			E('h2', [ _('MultiWAN Manager - Overview') ]),
			E('div', { class: 'cbi-section' }, [
				E('div', { 'id': 'mwan3-service-status' }, [
					E('em', { 'class': 'spinning' }, [ _('Collecting data ...') ])
				])
			])
		]);
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
})
