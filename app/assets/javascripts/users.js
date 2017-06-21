//for setting which tab should be active
window['users#upload'] = prepare_upload_users_page;
window['users#get_santas'] = prepare_get_santas_page;
window['users#index'] = prepare_users_page;
window['users#new'] = prepare_users_page;
window['users#edit'] = prepare_users_page;
window['users#show'] = prepare_users_page;

function prepare_users_page() {
	prepare_sidebar("users");
}

function prepare_upload_users_page() {
	prepare_sidebar("upload_users");
}

function prepare_get_santas_page() {
	prepare_sidebar("get_santas");
}