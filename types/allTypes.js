//components

/**
 * @global
 * @typedef {Object} specDeltaType
 * @property {string=} name
 * @property {(string|null)=} module
 * @property {string=} description
 * @property {Object=} env
 * @property {Array.<specType>=} components
 *
 */

//sharing

/**
 * @global
 * @typedef {Object} refMapType
 *
 */

/**
 * @global
 * @typedef {Object} mapOptionsType
 */

/**
 * @global
 * @typedef {Object} mapUpdateType
 * @property {number} version An initial version number for the map.
 * @property {Array.<string>} remove Map keys to delete.
 * @property {Array.<string|Object>} add  Key/value pairs to add to the map.
 *  They are laid out in the array as [key1, val1, key2, val2, ... *
 */

/**
 * @global
 * @typedef {Object} messagesType
 * @property {number} index  The first message in `messages` or
 * `UNKNOWN_ACK_INDEX`, i.e., `-1`,  if no messages.
 * @property {Array.<jsonType>} messages Messages received in the channel that
 * have not been acknowledged previously.
 *
 */


//redis

/**
 * @global
 * @typedef {Object} redisType
 * @property {number} port A port number for the service.
 * @property {string} hostname A host address for the service.
 * @property {string=} password A password for the service.
 */


/**
 * @global
 * @typedef {Object} changesType
 * @property {number} version An initial version number for the map.
 * @property {Array.<string>} remove Map keys to delete.
 * @property {Array.<Object>} add  Key/value pairs to add to the map. They are
 * laid out in the array as [key1, val1, key2, val2, ...
 */


//platform


/**
 * @global
 * @typedef {Object} remoteNodeNonNullType
 * @property {string} remoteNode The current lease owner.
 */

/**
 * @global
 * @typedef {null | remoteNodeNonNullType} remoteNodeType
 */



//iot

/**
 * @global
 * @typedef {Object} cronOptionsType
 * @property {boolean=} noSync Whether to skip cloud synchronization.
 */

/**
 * @global
 * @typedef {Object} commandType
 * @property {number} after Delay in msec from the start of the previous
 * command.
 * @property {string} method The name of the method to invoke.
 * @property {Array.<jsonType>} args The arguments to the method.
 */

/**
 * @global
 * @typedef {Object} bundleType
 * @property {number} start Starting time in msec (UTC since 1970).
 * @property {Array.<commandType>} commands A sequence of commands to execute.
 */


/**
 * @global
 * @typedef {Object} bundleObjectType
 */

/**
 * @global
 * @typedef {Object<string, Array.<string>>} bundleDescriptionType
 */

// ca

/**
 * @global
 * @typedef {Object} invocationType
 * @property {string} method
 * @property {Array.<string>} meta
 * @property {Array.<jsonType>} args
 *
 */

//session
/**
 * @global
 * @typedef {Object}  sessionBeginType
 * @property {string} nonce Unique session instance identifier.
 * @property {jsonType=} memento Information attached to the session.
 */

/**
 * @global
 * @typedef {Array.<jsonType>}  notificationType
 */

// security
/**
 * @global
 * @typedef {Object} ruleEngineType
 */

/**
 * @global
 * @typedef {Object} CANameType
 * @property {string=} caOwner
 * @property {string=} caLocalName
 */


/**
 * @global
 * @typedef {Object} simpleRuleType
 * @property {string} type Should be 'caf.simpleRule'.
 * @property {CANameType=} ac Enabled CAs.
 * @property {(Array.<string> | string)=} methods The methods enabled. All
 * enabled if this field is missing.
 */

/**
 * @global
 * @typedef {Object} aggregateRuleType
 * @property {string} type Should be 'caf.aggregateRule'.
 * @property {string} alias A local alias for the aggregate map.
 * @property {(Array.<string> | string)=} methods The methods enabled. All
 * enabled if this field is missing.
 */


/**
 * @global
 * @typedef {simpleRuleType | aggregateRuleType} ruleType
 */

/**
 * @global
 * @typedef {Object} tokenDescriptionType
 * @property {(string|null)=} appPublisher The publisher of the app hosting CAs.
 * A `null` value means  force the current value.
 * @property {(string|null)=} appLocalName The name of the app in the
 *  `appPublisher`  context.
 * @property {(string|null)=} caOwner  The owner of the CA.
 * @property {(string|null)=} caLocalName The name of the CA in the owner's
 * context.
 * @property {number=} durationInSec Time in sec before token expiration.
 */

/**
 * @global
 * @typedef {Array.<tokenDescriptionType> | tokenDescriptionType} tkDescArray
 */

/**
 * @global
 * @typedef {Object} tokenType
 * @property {string=} appPublisher The publisher of the app hosting CAs.
 * @property {string=} appLocalName The name of the app in the `appPublisher`
 *  context.
 * @property {string=} caOwner The owner of the CA.
 * @property {string=} caLocalName The name of the CA in the owner's context.
 * @property {number=} expiresAfter UTC expire time in msec since 1970.
 */

//cli

/**
 * @global
 * @typedef {function(Error?, any=):void} cbType
 *
 */


/**
 * @global
 * @typedef {Object} specType
 * @property {string} name
 * @property {string|null} module
 * @property {string=} description
 * @property {Object} env
 * @property {Array.<specType>=} components
 *
 */

/**
 * @global
 * @typedef {Object} specURLType
 * @property {string} appProtocol `http` or `https`.
 * @property {string} appPublisher The publisher of this app.
 * @property {string} appLocalName The local name of the app.
 * @property {string} appSuffix A URL suffix, e.g., `cafjs.com`.
 * @property {string} myId Name of the `from` CA, of the form
 * `caOwner-caLocalName`.
 */


/**
 * @global
 * @typedef {Object} cliPropsType
 * @property {string} caOwner Owner's name of the target CA.
 * @property {string} caLocalName Local name of the target CA.
 * @property {string} appPublisher The publisher of this app.
 * @property {string} appLocalName The local name of the app.
 * @property {string=} token  Authentication token for the `from` principal.
 * @property {string=} cacheKey A key to cache server side rendering.
 */

/**
 * @global
 * @typedef {Object | Array | string | number | null | boolean} jsonType
 *
 */

/**
 * @global
 * @typedef {Object<string, jsonType>} msgType
 *
 */

/**
 * @global
 * @typedef {Object} tokenFactoryOptionsType
 * @property {string=} password The password for the authentication service.
 * @property {string=} accountsURL The url for an authentication service.
 * @property {boolean=} unrestrictedToken True if the desired token
 * authenticates to all apps.
 * @property {number=} durationInSec Time in seconds from `now` till token
 * expires.
 * @property {Object=} securityClient A client implementation of the
 * authentication protocol. See `caf_srp` for an example.
 */

/**
 * @global
 * @typedef {Object} sessionOptionsType
 * @property {string} ca Name of the target CA, of the form
 * `caOwner-caLocalName`.
 * @property {string} from Name of the source CA, or equal to `ca` if the
 * client is the owner.
 * @property {string=} token Authentication token for the `from` principal.
 * @property {string=} session The logical session id.
 * @property {string=} appPublisher The publisher of this app.
 * @property {string=} appLocalName The local name of the app.
 * @property {boolean=} disableBackchannel No notifications are needed,
 * disable the backchannel.
 * @property {number=} maxRetries Number of error retries before closing a
 * session. If progress, they reset every `timeoutMsec`.
 * @property {number=} retryTimeoutMsec Time between retries in miliseconds.
 * @property {number=} timeoutMsec Max time in miliseconds for a request before
 * assuming an irrecoverable error, and closing the session.
 * @property {string=} cacheKey Custom key to cache server side rendering.
 * @property {boolean=} initUser Whether the owner in `from` is a new user that
 * has to be registered.
 * @property {function(string)=} log Custom function to log messages.
 * @property {function(msgType, cbType)=} newToken Custom function to negotiate
 * an authentication token.
 * @property {function(msgType, cbType)=} newURL Custom function to redirect
 * the session.
 * @property {function(string, Object, cbType)=} newUser Custom function to
 * register a new user.
 * @property {Object=} timeAdjuster Custom object to synchronize clocks with the
 * cloud. See `TimeAdjuster.js` for details.
 * @property {string=} password  See `tokenFactoryOptionsType`.
 * @property {string=} accountsURL  See `tokenFactoryOptionsType`.
 * @property {boolean=} unrestrictedToken See `tokenFactoryOptionsType`.
 * @property {number=} durationInSec See `tokenFactoryOptionsType`.
 * @property {Object=} securityClient See `tokenFactoryOptionsType`.
 * @property {number=} timeSmooth See `timeAdjusterOptionsType`.
 * @property {number=} timeMaxRTT  See `timeAdjusterOptionsType`.
 * @property {number=} timeMaxWindow  See `timeAdjusterOptionsType`.
 */


/**
 * @global
 * @typedef {Object} timeAdjusterOptionsType
 * @property {number=} timeSmooth Low pass filter coefficient.
 * Defaults to `1.0`, i.e., no filtering.
 * @property {number=} timeMaxRTT Maximum round trip time in msec before we
 * ignore it.
 * @property {number=} timeMaxWindow Size of the historical window. The
 *  algorithm  picks the quickest roundtrip in that window.
 */


/**
 * @global
 * @typedef {Object.<string, Object>} ctxType
 */
