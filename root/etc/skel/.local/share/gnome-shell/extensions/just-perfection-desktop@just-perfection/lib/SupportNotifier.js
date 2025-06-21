/**
 * Support Notifier Library
 *
 * @author     Javad Rahmatzadeh <j.rahmatzadeh@gmail.com>
 * @copyright  2020-2025
 * @license    GPL-3.0-only
 */

const TYPE = {
    NEVER: 0,
    NEW_RELEASE: 1,
};

/**
 * Support Notifier
 */
export class SupportNotifier
{
    /**
     * Current shell version
     *
     * @type {number|null}
     */
    #shellVersion = null;

    /**
     * Current extension version
     *
     * @type {number|null}
     */
    #extensionVersion = null;

    /**
     * Instance of Gio.Settings
     *
     * @type {Settings|null}
     */
    #settings = null;

    /**
     * Instance of current Extension
     *
     * @type {Extension|null}
     */
    #extension = null;

    /**
     * Class Constructor
     *
     * @param {Object} dependencies
     *   'MessageTray' reference to ui::messageTray
     *   'Main' reference to ui::main
     *   'Gio' reference to Gio
     * @param {number} shellVersion float in major.minor format
     * @param {number} extensionVersion integer
     * @param {Object} extension Extension
     */
    constructor(dependencies, shellVersion, extensionVersion, extension)
    {
        this._messageTray = dependencies['MessageTray'] || null;
        this._main = dependencies['Main'] || null;
        this._gio = dependencies['Gio'] || null;
        this.#settings = dependencies['Settings'] || null;

        this.#shellVersion = shellVersion;
        this.#extensionVersion = extensionVersion;
        this.#extension = extension;

        this.#registerSettingsSignals();
    }

    /**
     * register all signals for settings
     *
     * @returns {void}
     */
    #registerSettingsSignals()
    {
        this.#settings.connect('changed::support-notifier-type', () => {
            this.restart();
        });
    }

    /**
     * start support notifier service
     *
     * @returns {void}
     */
    start()
    {
        let type = this.#settings.get_int('support-notifier-type');

        if (type === TYPE.NEW_RELEASE) {
            if (!this.#isShownForCurrentVersion()) {
                this.#showNotification();
            }
        }
    }

    /**
     * stop support notifier service
     *
     * @returns {void}
     */
    stop()
    {
    }

    /**
     * restart support notifier service
     *
     * @returns {void}
     */
    restart()
    {
        this.stop();
        this.start();
    }

    /**
     * whether the notification showed for the current extension version
     *
     * @returns {boolean}
     */
    #isShownForCurrentVersion()
    {
        let showedVersion = this.#settings.get_int('support-notifier-showed-version');

        return this.#extensionVersion <= showedVersion;
    }

    /**
     * show notification
     *
     * @returns {void}
     */
    #showNotification()
    {
        let title = "Support Just Perfection Extension";
        let body = "The future of the Just Perfection extension depends on your support! " +
            "Your donation will help add new features and updates. " +
            "Please consider making a donation." +
            "\r\r" +
            "<i>Crypto donations are preferred since there are no platform fees, " +
            "and 100% of your donation is received directly.</i>";

        const source = this.#getSource();
        const notification = this.#getNotification(source, title, body);

        notification.addAction('Buy Me a Coffee', () => {
            this._gio.AppInfo.launch_default_for_uri('https://www.buymeacoffee.com/justperfection', null);
            notification.destroy();
        });

        notification.addAction('Donate Crypto', () => {
            this.#extension.openPreferences();
            notification.destroy();
        });

        notification.addAction("Don't show again!", () => {
            this.#settings.set_int('support-notifier-type', TYPE.NEVER);
            notification.destroy();
        });

        if (this.#shellVersion >= 46) {
            source.addNotification(notification);
        } else {
            source.showNotification(notification);
        }

        this.#settings.set_int('support-notifier-showed-version', this.#extensionVersion);
    }

    /**
     * get system notification source
     *
     * @returns {MessageTray.Source}
     */
    #getSource()
    {
        const source
            = (this.#shellVersion >= 46)
            ? this._messageTray.getSystemSource()
            : new this._messageTray.SystemNotificationSource();

        if (this.#shellVersion < 46) {
            this._main.messageTray.add(source);
        }

        source.title = 'Just Perfection Extension';
        source.iconName = 'application-x-addon-symbolic';

        return source;
    }

    /**
     * get notification
     *
     * @param {MessageTray.Source} source
     * @param {string} title
     * @param {string} body
     *
     * @returns {MessageTray.Notification}
     */
    #getNotification(source, title, body)
    {
        const notification
            = (this.#shellVersion >= 46)
            ? new this._messageTray.Notification({source, title, body})
            : new this._messageTray.Notification(source, title, body, {bannerMarkup: true});

        notification.useBodyMarkup = true;
        notification.resident = true;
        notification.iconName = 'emblem-favorite-symbolic';
        notification.urgency = this._messageTray.Urgency.CRITICAL;

        return notification;
    }
}