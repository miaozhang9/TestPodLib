
cordova.define("qhCordova-plugin-navigationBar.navigationBar", function(require, exports, module) {

var exec = require('cordova/exec');
var platform = require('cordova/platform');

module.exports = {

    setNaviBarTitle: function(title) {
        if (typeof title === 'string') {
            exec(null, null, "QHNavigationbarPlugin", "setNaviBarTitle", [title]);
        }
    },

    showNavigationBar: function(show) {
        if (typeof show === 'boolean') {
            exec(null, null, "QHNavigationbarPlugin", "showNavigationBar", [show]);
        }
    },
               
    setNavibarTitleColor: function(color) {
       if (typeof color === 'string') {
            exec(null, null, "QHNavigationbarPlugin", "setNavibarTitleColor", [color]);
       }
    },
               
    setNaviBarColor: function(color) {
        if (typeof color === 'string') {
            exec(null, null, "QHNavigationbarPlugin", "setNaviBarColor", [color]);
        }
    },
               
    openNewPageWithUrl: function(url) {
        if (typeof url === 'string') {
               exec(null, null, "QHNavigationbarPlugin", "openNewPageWithUrl", [url]);
        }
    },
               
    closeAllPage: function(isCloseAll) {
      
            exec(null, null, "QHNavigationbarPlugin", "closeAllPage", [isCloseAll]);
       
   },
               
   openLaunchLoginPage: function() {
   
               exec(null, null, "QHNavigationbarPlugin", "openLaunchLoginPage", []);
   
   },
               
   openNewPageWithParams: function(params) {
//       if (typeof params === 'object') {
               exec(null, null, "QHNavigationbarPlugin", "openNewPageWithParams", [params]);
//        }
   },

   mulFunctionTlBack: function(isVisible) {
       if (typeof isVisible === 'boolean') {
               exec(null, null, "QHNavigationbarPlugin", "mulFunctionTlBack", [isVisible]);
       }
   }
   ,
   
   setNativeBackControl: function(backControl) {
       if (typeof backControl === 'string') {
               exec(null, null, "QHNavigationbarPlugin", "setNativeBackControl", [backControl]);
           }
   },
   setNaviRightBarButtonItemUI: function(params) {
       
       exec(null, null, "QHNavigationbarPlugin", "setNaviRightBarButtonItemUI", params);
       
   }
               
               
}
});


















