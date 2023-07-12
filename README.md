<h1>shibboleth-idp</h1>
<h1>Welcome to the configuration guide</h1>
 <h1>Requirements</h1>
 <ul>
   <li>docker</li>
   <li>docker compose</li>
   <li>Ldap server</li>
   <li>service provider</li>
 </ul>

<h1>Configuration</h1>
<h3>Please modify the settings below according to your requirements: </h3>
<h3>list files that you have to modify </h3>

<ul>
  <li><h1> config/shib-idp/conf/idp.properties </h1></li>
  <img src="./images/idp-properties.png">
  <li> <h1>config/shib-idp/conf/ldap.properties </h1></li>
  <img src="./images/ldap-pro.png">
   <img src="./images/ldap-pro-2.png">  
  <li> <h1> config/shib-idp/conf/metadata-providers.xml </h1></li>
  <img src="./images/metadata-providers.png">
  <li> <h1> config/shib-idp/metadata/sp-metadata.xml </h1></li>
  <img src="./images/sp-metadata.png">
  <li> <h1> messages/messages.properties </h1> </li>
 <img src="./images/template.png">
</ul>
