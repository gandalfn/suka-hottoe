/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Device.vala
 * Copyright (C) Nicolas Bruguier 2018 <gandalfn@club-internet.fr>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 */

public abstract class Hottoe.Device : GLib.Object {
    public unowned Manager manager { get; construct; }
    public string name { get; construct; }
    public string display_name { get; construct; }
    public string description { get; construct; }
    public string icon_name { get; construct; }
    public abstract bool active { get; }
    public abstract unowned Profile? active_profile { get; set; }
    public abstract bool enable_equalizer { get; set; }
    public abstract unowned Equalizer? equalizer { get; }

    public signal void changed ();
    public signal void channel_added (Channel in_channel);
    public signal void channel_removed (Channel in_channel);

    public abstract Profile get_profile (string in_name);
    public abstract Profile[] get_profiles ();

    public abstract Port[] get_output_ports ();
    public abstract Port[] get_input_ports ();

    public abstract bool contains (Channel in_channel);

    public Channel[] get_output_channels () {
        Channel[] channels = {};

        foreach (var channel in manager.get_output_channels ()) {
            foreach (var port in get_output_ports ()) {
                if (channel.port == port) {
                    channels += channel;
                }
            }
        }

        return channels;
    }

    public Channel[] get_input_channels () {
        Channel[] channels = {};

        foreach (var channel in manager.get_input_channels ()) {
            foreach (var port in get_input_ports ()) {
                if (channel.port == port) {
                    channels += channel;
                }
            }
        }

        return channels;
    }

    public abstract string to_string ();
}
