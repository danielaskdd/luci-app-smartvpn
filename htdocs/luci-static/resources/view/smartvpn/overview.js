'use strict';
'require fs';
'require ui';
'require uci';
'require form';
'require tools.widgets as widgets';

/*
	button handling
*/
async function handleAction(ev) {
	if (ev === 'timer') {
		L.ui.showModal(_('Refresh Timer'), [
			E('p', _('To keep your adblock lists up-to-date, you should setup an automatic update job for these lists.')),
			E('div', { 'class': 'left', 'style': 'display:flex; flex-direction:column' }, [
				E('h5', _('Existing job(s)')),
				E('textarea', {
					'id': 'cronView',
					'style': 'width: 100% !important; padding: 5px; font-family: monospace',
					'readonly': 'readonly',
					'wrap': 'off',
					'rows': 5
				})
			]),
			E('div', { 'class': 'left', 'style': 'display:flex; flex-direction:column' }, [
				E('label', { 'class': 'cbi-input-select', 'style': 'padding-top:.5em' }, [
				E('h5', _('Set/Replace a new adblock job')),
				E('select', { 'class': 'cbi-input-select', 'id': 'timerA' }, [
					E('option', { 'value': 'start' }, 'Start'),
					E('option', { 'value': 'reload' }, 'Reload'),
					E('option', { 'value': 'restart' }, 'Restart')
				]),
				'\xa0\xa0\xa0',
				_('Adblock action')
				]),
				E('label', { 'class': 'cbi-input-text', 'style': 'padding-top:.5em' }, [
				E('input', { 'class': 'cbi-input-text', 'id': 'timerH', 'maxlength': '2' }, [
				]),
				'\xa0\xa0\xa0',
				_('The hours portition (req., range: 0-23)')
				]),
				E('label', { 'class': 'cbi-input-text', 'style': 'padding-top:.5em' }, [
				E('input', { 'class': 'cbi-input-text', 'id': 'timerM', 'maxlength': '2' }),
				'\xa0\xa0\xa0',
				_('The minutes portion (opt., range: 0-59)')
				]),
				E('label', { 'class': 'cbi-input-text', 'style': 'padding-top:.5em' }, [
				E('input', { 'class': 'cbi-input-text', 'id': 'timerD', 'maxlength': '13' }),
				'\xa0\xa0\xa0',
				_('The day of the week (opt., values: 1-7 possibly sep. by , or -)')
				])
			]),
			E('div', { 'class': 'right' }, [
				E('button', {
					'class': 'btn',
					'click': L.hideModal
				}, _('Cancel')),
				' ',
				E('button', {
					'class': 'btn cbi-button-action',
					'click': ui.createHandlerFn(this, function(ev) {
						var action  = document.getElementById('timerA').value;
						var hours   = document.getElementById('timerH').value;
						var minutes = document.getElementById('timerM').value || '0';
						var days    = document.getElementById('timerD').value || '*';
						if (hours) {
							L.resolveDefault(fs.exec_direct('/etc/init.d/adblock', ['timer', action, hours, minutes, days]))
							.then(function(res) {
								if (res) {
									ui.addNotification(null, E('p', _('The Refresh Timer could not been updated.')), 'error');
								} else {
									ui.addNotification(null, E('p', _('The Refresh Timer has been updated.')), 'info');
								}
							});
						} else {
							document.getElementById('timerH').focus();
							return
						}
						L.hideModal();
					})
				}, _('Save'))
			])
		]);
		L.resolveDefault(fs.read_direct('/etc/crontabs/root'), ' ')
		.then(function(res) {
			document.getElementById('cronView').value = res.trim();
		});
		document.getElementById('timerH').focus();
		return
	}

	if (ev === 'suspend') {
		if (document.getElementById('status') && document.getElementById('btn_suspend') && document.getElementById('status').textContent.substr(0,6) === 'paused') {
			document.querySelector('#btn_suspend').textContent = 'Suspend';
			ev = 'resume';
		} else if (document.getElementById('status') && document.getElementById('btn_suspend')) {
			document.querySelector('#btn_suspend').textContent = 'Resume';
		}
	}

	L.Poll.start();
	fs.exec_direct('/etc/init.d/adblock', [ev])
	var running = 1;
	while (running === 1) {
		await new Promise(r => setTimeout(r, 1000));
		L.resolveDefault(fs.read_direct('/var/run/adblock.pid')).then(function(res) {
			if (!res) {
				running = 0;
			}
		})
	}
	L.Poll.stop();
}

return L.view.extend({
	load: function() {
		return Promise.all([
			L.resolveDefault(fs.exec_direct('/usr/sbin/smartvpn.sh', ['status']), {}),
			uci.load('smartvpn')
		]);
	},

	render: function(result) {
		var m, s, o;

		m = new form.Map('smartvpn', 'SmartVPN', _('Status and overview of SmartVPN service.'));

		/*
			poll runtime information
		*/
		pollData: L.Poll.add(function() {
			return L.resolveDefault(fs.read_direct('/var/run/softether_vpn.lock'), 'null').then(function(res) {
				var info = res;			/* 拆分显示内容 */
				var status = document.getElementById('status');
				if (info && res) {
					status.textContent = info;
				}
				var mainland = document.getElementById('mainland');
				if (mainland && res) {
					mainland.textContent = '100';
				}
				var hongkong = document.getElementById('hongkong');
				if (hongkong && res) {
					hongkong.textContent = '99';
				}
				var oversea = document.getElementById('oversea');
				if (oversea && res) {
					oversea.textContent = '98';
				}
			});
		}, 1);

		/*
			runtime information and buttons
		*/
		s = m.section(form.NamedSection, 'global');
		s.render = L.bind(function(view, section_id) {
			return E('div', { 'class': 'cbi-section' }, [
				E('h3', _('Information')), 
				E('div', { 'class': 'cbi-value', 'style': 'margin-bottom:5px' }, [
				E('label', { 'class': 'cbi-value-title', 'style': 'padding-top:0rem' }, _('Status')),
				E('div', { 'class': 'cbi-value-field', 'id': 'status', 'style': 'font-weight: bold;margin-bottom:5px;color:#37c' },'\xa0')]),
				E('div', { 'class': 'cbi-value', 'style': 'margin-bottom:5px' }, [
				E('label', { 'class': 'cbi-value-title', 'style': 'padding-top:0rem' }, _('Mainland ips')),
				E('div', { 'class': 'cbi-value-field', 'id': 'mainland', 'style': 'font-weight: bold;margin-bottom:5px;color:#37c' },'-')]),
				E('div', { 'class': 'cbi-value', 'style': 'margin-bottom:5px' }, [
				E('label', { 'class': 'cbi-value-title', 'style': 'padding-top:0rem' }, _('Hongkong ips')),
				E('div', { 'class': 'cbi-value-field', 'id': 'hongkong', 'style': 'font-weight: bold;margin-bottom:5px;color:#37c' },'-')]),
				E('div', { 'class': 'cbi-value', 'style': 'margin-bottom:5px' }, [
				E('label', { 'class': 'cbi-value-title', 'style': 'padding-top:0rem' }, _('Oversea ips')),
				E('div', { 'class': 'cbi-value-field', 'id': 'oversea', 'style': 'font-weight: bold;margin-bottom:5px;color:#37c' },'-')]),
				E('div', { class: 'right' }, [
					E('button', {
						'class': 'cbi-button cbi-button-apply',
						'click': ui.createHandlerFn(this, function() {
							return handleAction('snapshot');
						})
					}, [ _('Save snapshot') ]),
					'\xa0\xa0\xa0',
					E('button', {
						'class': 'cbi-button cbi-button-apply',
						'id': 'btn_suspend',
						'click': ui.createHandlerFn(this, function() {
							return handleAction('restore');
						})
					}, [ _('Restore snapshot') ]),
					'\xa0\xa0\xa0',
					E('button', {
						'class': 'cbi-button cbi-button-reset',
						'click': ui.createHandlerFn(this, function() {
							return handleAction('restart');
						})
					}, [ _('Hard restart') ]),
					'\xa0\xa0\xa0',
					E('button', {
						'class': 'cbi-button cbi-button-save',
						'click': ui.createHandlerFn(this, function() {
							return handleAction('reload');
						})
					}, [ _('Soft restart') ])
				])
			]);
		}, o, this);
		this.pollData;

		/*
			config section
		*/
		s = m.section(form.NamedSection, 'global', 'adblock', _('Settings'));
		s.addremove = false;
		o = s.option(form.Flag, 'vpn_enabled', _('Enabled'), _('Enable the adblock service.'));
		o.rmempty = false;
		return m.render();
	},
	handleReset: null
});
