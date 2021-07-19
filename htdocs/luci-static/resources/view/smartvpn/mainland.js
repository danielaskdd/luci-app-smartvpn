'use strict';
'require fs';
'require ui';

var filename = '/etc/smartvpn/proxy_mainland.txt';

return L.view.extend({
	load: function() {
		return L.resolveDefault(fs.read_direct(filename), '');
	},
	handleSave: function(ev) {
		var value = ((document.querySelector('textarea').value || '').trim().toLowerCase().replace(/\r\n/g, '\n').replace(/[^a-z0-9\.\-\#\n]/g, '')) + '\n';
		return fs.write(filename, value)
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
				E('textarea', { 'id': 'hostlist',
					'style': 'width: 100% !important; padding: 5px; font-family: monospace',
					'spellcheck': 'false',
					'wrap': 'off',
					'rows': 25
				}, [ hostlist != null ? hostlist : '' ])
			)
		]);
	},
	handleReset: function(ev) {
		L.resolveDefault(fs.read_direct(filename), '').then(function(hostlist) {
			document.querySelector('textarea').value = hostlist;
			ui.addNotification(null, E('p', _('Restore hosts list to original content')), 'info');	
		}).catch(function(e) {
			ui.addNotification(null, E('p', _('Unable to read file: %s').format(e.message)));
		});
	},
	handleSaveApply: null
});
