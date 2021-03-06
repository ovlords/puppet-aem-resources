aem_resources::enable_saml { 'Enable SAML authentication':
  key_store_password         => 'somepassword',
  service_ranking            => 5002,
  idp_http_redirect          => true,
  create_user                => true,
  default_redirect_url       => '/sites.html',
  user_id_attribute          => 'NameID',
  default_groups             => ['def-groups'],
  file                       => '/tmp/shinesolutions/puppet-aem-resources/saml.crt',
  add_group_memberships      => true,
  path                       => ['/'],
  synchronize_attributes     => [
    'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname\=profile/givenName',
    'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname\=profile/familyName',
    'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress\=profile/email'
  ],
  clock_tolerance            => 60,
  group_membership_attribute => 'http://temp/variable/aem-groups',
  idp_url                    => 'https://federation.prod.com/adfs/ls/IdpInitiatedSignOn.aspx?RequestBinding\=HTTPPost&loginToRp\=https://prod-aemauthor.com/saml_login',
  logout_url                 => 'https://federation.prod.com/adfs/ls/IdpInitiatedSignOn.aspx',
  service_provider_entity_id => 'https://prod-aemauthor.com/saml_login',
  handle_logout              => true,
  use_encryption             => false,
  name_id_format             => 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient',
  digest_method              => 'http://www.w3.org/2001/04/xmlenc#sha256',
  signature_method           => 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256',
  aem_id                     => 'author',
}
