angular.module("app.auth", ['firebase', 'ngCookies'])

# gives you access to an authenticated firebase url ($ref.base)
# the user's netid ($ref.netid) and the user's info ($ref.me)
.factory '$ref' ($cookies, $rootScope, $firebase, $window)->
    refScope = $rootScope.$new()
    cookieData = JSON.parse($cookies.casInfo)
    netid = cookieData.netid
    firebase = new Firebase($PROCESS_ENV_FIREBASE)
    do
        error <- firebase.auth(cookieData.token)
        if error
            console.log('got an error')
            if error.code is "EXPIRED_TOKEN"
                $window.location.assign("/refresh?url=#{encodeURIComponent $window.location}")
            else console.log('Cookie data corrupted', error)
        else
            firebase.child("users/#{netid}").update({exists: true})
            $firebase(firebase.child("users/#{netid}")).$bind(refScope, "me").then (unbind)->
                $rootScope.$broadcast('newuser') if not refScope.me.name?
                $rootScope.$broadcast('loggedin')
    refScope.base = firebase
    refScope.netid = netid
    refScope.loggedin = false
    return refScope

# returns a function that takes a list of netid
# and returns an auto-updating map of netids to users
.factory '$trackConnected' ($ref)->
    (connections)!-> 
      conRef = $ref.base.root!child '.info/connected'
      childRef = connections.child($ref.netid)
      conRef.on 'value' (snap)!->
        if (snap.val!)
          childRef.set {name: $ref.me.name}
          childRef.onDisconnect!remove!

# $group.name gives the currently selected group name
# $group.setGroup takes a group id to set as currently selected
# call $group.clearGroup when back on the group page
.factory '$group' ($ref, $rootScope, $timeout)->
    result = {}
    result.props = $rootScope.$new()
    result.setGroup = (groupid)!->
        $timeout( (!->
            $ref.base.child("group/#{groupid}/name").on 'value' (snapshot)->
                result.props.$apply(->result.props.name = snapshot.val!)), 0)
    result.clearGroup = !-> result.props.name = ''
    return result
