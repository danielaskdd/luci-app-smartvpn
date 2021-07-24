/*
	SmartVPN overview page
*/

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
	if (ev === 'reload' || ev === 'restart') {
		L.Poll.start();   //确保页面开启刷新

		if (ev === 'reload') {
			fs.exec_direct('/usr/sbin/smartvpn.sh', ['on']);
		} else {
			fs.exec_direct('/usr/sbin/smartvpn.sh', ['on', 'hard']);
		}			
		var running = 1;
		while (running === 1) {
			await new Promise(r => setTimeout(r, 1000));
			L.resolveDefault(fs.read_direct('/var/run/smartvpn.lock')).then(function(res) {
				if (!res) {
					running = 0;
				}
			})
		}
	}
	if (ev === 'save' || ev === 'restore') {
		L.Poll.start();   //确保页面开启刷新

		fs.exec_direct('/usr/sbin/smartvpn.sh', [ev]);

		var running = 1;
		while (running === 1) {
			await new Promise(r => setTimeout(r, 1000));
			L.resolveDefault(fs.read_direct('/var/run/smartvpn.lock')).then(function(res) {
				if (!res) {
					running = 0;
				}
			})
		}
	}
}

return L.view.extend({
	load: function() {
		return L.resolveDefault(fs.exec_direct('/usr/sbin/smartvpn.sh', ['status', 'short']), '');
	},

	render: function(res) {
		var m, s, o;

		var result = res.split("\n");

		m = new form.Map('smartvpn', 'SmartVPN', _('Select the best route for Internet Access.'));

		/*
			poll runtime information
		*/
		pollData: L.Poll.add(function() {
			return L.resolveDefault(fs.read_direct('/var/run/smartvpn.lock')).then(function(res) {

				var status = document.getElementById('status');
				var reload = document.getElementById('btn_reload');
				var snapshot = document.getElementById('btn_snapshot');
				var restore = document.getElementById('btn_restore');

				if (status && res) {  // status is pending
					if (!status.classList.contains("spinning")) {
						status.classList.add("spinning");
					}
				} else if (status) {
					if (status.classList.contains("spinning")) {
						status.classList.remove("spinning");
						// L.Poll.stop();   //不需要停止,持续刷新状态
					}
				}

				L.resolveDefault(fs.exec_direct('/usr/sbin/smartvpn.sh', ['status', 'short']), '').then(function(res) {

					var result = res.split("\n");

					if (result[0].indexOf("ON")>0) {
						reload.disabled=false;
						snapshot.disabled=false;
						restore.disabled=false;
					} else {
						reload.disabled=true;
						snapshot.disabled=true;
						restore.disabled=true;
					}

					if (status && result[0]) {
						status.textContent = result[0];
					}
					
					var mainland = document.getElementById('mainland');
					if (mainland && result[1]) {
						mainland.textContent = result[1];
					}

					var hongkong = document.getElementById('hongkong');
					if (hongkong && result[1]) {
						hongkong.textContent = result[2];
					}

					var oversea = document.getElementById('oversea');
					if (oversea && result[1]) {
						oversea.textContent = result[3];
					}
				})					
			})
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
				E('div', { 'class': 'cbi-value-field', 'id': 'status', 'style': 'font-weight: bold;margin-bottom:5px;color:#37c' },result[0])]),
				E('div', { 'class': 'cbi-value', 'style': 'margin-bottom:5px' }, [
				E('label', { 'class': 'cbi-value-title', 'style': 'padding-top:0rem' }, _('Mainland ips')),
				E('div', { 'class': 'cbi-value-field', 'id': 'mainland', 'style': 'font-weight: bold;margin-bottom:5px;color:#37c' },result[1])]),
				E('div', { 'class': 'cbi-value', 'style': 'margin-bottom:5px' }, [
				E('label', { 'class': 'cbi-value-title', 'style': 'padding-top:0rem' }, _('Hongkong ips')),
				E('div', { 'class': 'cbi-value-field', 'id': 'hongkong', 'style': 'font-weight: bold;margin-bottom:5px;color:#37c' },result[2])]),
				E('div', { 'class': 'cbi-value', 'style': 'margin-bottom:5px' }, [
				E('label', { 'class': 'cbi-value-title', 'style': 'padding-top:0rem' }, _('Oversea ips')),
				E('div', { 'class': 'cbi-value-field', 'id': 'oversea', 'style': 'font-weight: bold;margin-bottom:5px;color:#37c' },result[3])]),
				E('div', { class: 'right' }, [
					E('button', {
						'class': 'cbi-button cbi-button-apply',
						'id': 'btn_snapshot',
						'click': ui.createHandlerFn(this, function() {
							return handleAction('save');
						})
					}, [ _('Save snapshot') ]),
					'\xa0\xa0\xa0',
					E('button', {
						'class': 'cbi-button cbi-button-apply',
						'id': 'btn_restore',
						'click': ui.createHandlerFn(this, function() {
							return handleAction('restore');
						})
					}, [ _('Restore snapshot') ]),
					'\xa0\xa0\xa0',
					// E('button', {
					// 	'class': 'cbi-button cbi-button-reset',
					// 	'id': 'btn_restart',
					// 	'click': ui.createHandlerFn(this, function() {
					// 		return handleAction('restart');
					// 	})
					// }, [ _('Hard restart') ]),
					// '\xa0\xa0\xa0',
					E('button', {
						'class': 'cbi-button cbi-button-save',
						'id': 'btn_reload',
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
		s = m.section(form.NamedSection, 'global', 'smartvpn', _('Settings'));
		s.addremove = false;
		o = s.option(form.Flag, 'vpn_enable', _('Enabled'), _('Enable SmartVPN service.'));
		o.rmempty = false;

		o = s.option(form.Value, 'dns_mainland', _('mainland DNS'), _('The DNS ip from your ISP or fastest DNS for mainland getway.'));
		o.placeholder = '127.0.0.1 or 119.29.29.29';
		o.rmempty = false;
		o.datatype = "ip4addr";

		o = s.option(form.Value, 'init_cmd', _('Init cmd'), _('Restore initial configuration(do it at your own risk).'));
		o.placeholder = 'all | network | vpnserver | mwan3';
		o.rmempty = true;
		o.datatype = "string";

		return m.render();
	},
	handleReset: null
});
