#!/bin/bash

set -e
U=http://localhost:9130
tenant=testlib1
username=testing_admin
password=admin
# curl -f -d"{\"id\":\"$tenant\"}" $U/_/proxy/tenants
curl -d'{"name":"DB_HOST","value":"localhost"}' $U/_/env
curl -d'{"name":"DB_PORT","value":"5432"}' $U/_/env
curl -d'{"name":"DB_USERNAME","value":"okapi"}' $U/_/env
curl -d'{"name":"DB_PASSWORD","value":"okapi25"}' $U/_/env
curl -d'{"name":"DB_DATABASE","value":"okapi"}' $U/_/env

# Set of modules that are necessary to bootstrap admin user
CORE_MODULES="mod-users mod-login mod-permissions"
# CORE_MODULES=""

TEST_MODULES="mod-settings"

compile_module() {
	local m=$1
	if test ! -d $m; then	
		git clone --recurse-submodules git@github.com:folio-org/$m

	fi
	if test ! -d $m; then
		echo "$m missing. git clone failed?"
		exit 1
	fi
	cd $m
	mvn -DskipTests -Dmaven.test.skip=true verify
	cd ..
}
register_module() {
	local m=$2
	echo "Register module $m"
	local md=$m/target/ModuleDescriptor.json
	if test ! -f $md; then
		compile_module $m
	fi
	if test ! -f $md; then
		echo "$md missing pwd=`pwd`"
		exit 1
	fi
	if test "$1" != "x"; then
		OPT=-HX-Okapi-Token:$1
	else
		OPT=""
	fi
	curl -s $OPT -d@$md $U/_/proxy/modules -o /dev/null
}

deploy_module() {
	local m=$2
	echo "Deploy module $m"
	if test "$1" != "x"; then
		OPT=-HX-Okapi-Token:$1
	else
		OPT=""
	fi
	local dd=$m/target/DeploymentDescriptor.json
	curl -s $OPT -d@$dd $U/_/deployment/modules -o /dev/null
}

deploy_modules() {
	for m in $2; do
		register_module $1 $m
	done
	for m in $2; do
		deploy_module $1 $m
	done
}

install_modules() {
	local j="["
	local sep=""
	for m in $3; do
		j="$j $sep {\"action\":\"$2\",\"id\":\"$m\"}"
		sep=","
	done
	j="$j]"
	if test "$1" != "x"; then
		OPT=-HX-Okapi-Token:$1
	else
		OPT=""
	fi
	curl -s $OPT "-d$j" "$U/_/proxy/tenants/$tenant/install?purge=true&tenantParameters=loadReference%3Dtrue%2CloadSample%3Dtrue"
}

okapi_curl() {
	if test "$1" != "x"; then
		local OPT="-HX-Okapi-Token:$1"
	else
		local OPT="-HX-Okapi-Tenant:$tenant"
	fi
	shift
	curl -s $OPT -HContent-Type:application/json $*
}

make_adminuser() {
	local username=$2
	local password=$3
	
	uid=`uuidgen`
	okapi_curl $1 -XDELETE "$U/users?query=username%3D%3D$username"
	okapi_curl $1 -d"{\"username\":\"$username\",\"id\":\"$uid\",\"active\":true}" $U/users
	okapi_curl $1 -d"{\"username\":\"$username\",\"userId\":\"$uid\",\"password\":\"$password\"}" $U/authn/credentials
	puid=`uuidgen`
	okapi_curl $1 -d"{\"id\":\"$puid\",\"userId\":\"$uid\",\"permissions\":[\"okapi.all\",\"perms.all\",\"users.all\",\"login.item.post\",\"perms.users.assign.immutable\"]}" $U/perms/users
}

login_admin() {
	curl -s -Dheaders -HX-Okapi-Tenant:$tenant -HContent-Type:application/json -d"{\"username\":\"$username\",\"password\":\"$password\"}" $U/authn/login
token=`awk '/x-okapi-token/ {print $2}' <headers|tr -d '[:space:]'`
}

deploy_modules x "$CORE_MODULES"

deploy_modules x mod-authtoken

install_modules x enable "$CORE_MODULES"
install_modules x enable okapi

make_adminuser x $username $password

install_modules x enable mod-authtoken

login_admin

deploy_modules $token "$TEST_MODULES"

install_modules $token enable "$TEST_MODULES"

cat >md.json <<END
{
   "id":"mod-use-settings-1.0.0",
   "provides": [],
   "permissionSets": [
    {
      "permissionName": "mod-settings.global.read.gscope",
      "displayName": "gscope: global read"
    },
    {
      "permissionName": "mod-settings.global.write.gscope",
      "displayName": "gscope: global write"
    },
    {
      "permissionName": "mod-settings.owner.read.oscope",
      "displayName": "oscope: owner read"
    },
    {
      "permissionName": "mod-settings.owner.write.oscope",
      "displayName": "oscope: owner write"
    },
    {
      "permissionName": "mod-settings.user.read.uscope",
      "displayName": "uscope: user read"
    },
    {
      "permissionName": "mod-settings.user.write.uscope",
      "displayName": "uscope: user write"
    }
   ]
}
END

okapi_curl $token -d@md.json $U/_/proxy/modules

install_modules $token enable "mod-use-settings"

echo "Adding permissions to puid=$puid"
okapi_curl $token -d'{"permissionName":"mod-settings.entries.all"}' $U/perms/users/$puid/permissions
okapi_curl $token -d'{"permissionName":"mod-settings.global.write.gscope"}' $U/perms/users/$puid/permissions
okapi_curl $token -d'{"permissionName":"mod-settings.global.read.gscope"}' $U/perms/users/$puid/permissions
okapi_curl $token -d'{"permissionName":"mod-settings.owner.write.oscope"}' $U/perms/users/$puid/permissions
okapi_curl $token -d'{"permissionName":"mod-settings.owner.read.oscope"}' $U/perms/users/$puid/permissions

echo "puid=$puid"
echo "uid=$uid"
echo "Waiting 61 seconds for the permissions to take effect (mod-authtoken cache)"
sleep 21
echo "40 go to"
sleep 20
echo "20 to go"
sleep 20

id=`uuidgen`
okapi_curl $token -d"{\"id\":\"$id\",\"scope\":\"gscope\",\"key\":\"k1\",\"value\":{\"i\":1}}" $U/settings/entries
id=`uuidgen`
okapi_curl $token -d"{\"id\":\"$id\",\"scope\":\"oscope\",\"key\":\"k2\",\"value\":{\"i\":2},\"userId\":\"$uid\"}" $U/settings/entries
okapi_curl $token $U/settings/entries