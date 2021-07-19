'use strict';
'require fs';
'require ui';

return L.view.extend({
	load: function() {
		return L.resolveDefault(fs.read_direct('/etc/smartvpn/proxy_mainland.txt'), '');
	},
	handleSave: function(ev) {
		var value = ((document.querySelector('textarea').value || '').trim().toLowerCase().replace(/\r\n/g, '\n').replace(/[^a-z0-9\.\-\#\n]/g, '')) + '\n';
		return fs.write('/etc/smartvpn/proxy_mainland.txt', value)
			.then(function(rc) {
				document.querySelector('textarea').value = value;
				ui.addNotification(null, E('p', _('Changes have been saved. You should restart SmartVPN to take effect.')), 'info');
			}).catch(function(e) {
				ui.addNotification(null, E('p', _('Unable to save changes: %s').format(e.message)));
			});
	},
	render: function(hostlist) {
		return E([
			E('p', {},
				_('Listed below are the hosts must be accessed via default gateway of your router.<br /> \
				Please note: add only one domain or network segment per line. Comments introduced with \'#\' are allowed')),
			E('p', {},
				E('textarea', {
					'style': 'width: 100% !important; padding: 5px; font-family: monospace',
					'spellcheck': 'false',
					'wrap': 'off',
					'rows': 25
				}, [ hostlist != null ? hostlist : '' ])
			)
		]);
	},
	handleSaveApply: null,
	handleReset: null
});
