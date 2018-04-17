/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * VuMeter.vala
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 */

public class SukaHottoe.Widgets.VuMeter : Gtk.DrawingArea {
    private Monitor m_monitor;
    private double m_value;
    private int64 m_last_frame = 0;
    private Granite.Drawing.BufferSurface m_buffer;

    public unowned Channel channel { get; construct; }
    public double level { get; set; default = 100.0; }
    public int nb_bars { get; set; default = 10; }
    public Gtk.Orientation orientation { get; set; default = Gtk.Orientation.VERTICAL; }

    construct {
        m_monitor = channel.create_monitor ();
        m_monitor.peak.connect (on_monitor_peak);
        m_monitor.paused.connect (on_monitor_paused);

        channel.manager.bind_property ("enable-monitoring", m_monitor, "active", GLib.BindingFlags.SYNC_CREATE);
        m_monitor.bind_property ("active", this, "sensitive");
        channel.bind_property ("volume", this, "level", GLib.BindingFlags.SYNC_CREATE);

        height_request = 8;

        add_tick_callback (on_tick);
    }

    public VuMeter (Channel in_channel) {
        GLib.Object (
            channel: in_channel
        );
    }

    public override bool draw (Cairo.Context in_ctx)
        requires (nb_bars > 0) {
        int width = get_allocated_width ();
        int height = get_allocated_height ();

        double remanence = 1;
        double back_rem = 0.2;

        // calculate size of bars
        int bar_width = 0;
        int bar_height = 0;
        int space = 0;
        if (orientation == Gtk.Orientation.VERTICAL) {
            bar_width = (int)((double)width / (double)nb_bars);
            bar_height = height;
            space = (int)((double)bar_width* 0.1);
            bar_width -= space;
        } else  {
            bar_height = (int)((double)height / (double)nb_bars);
            bar_width = width;
            space = (int)((double)bar_height* 0.1);
            bar_height -= space;
        }

        double yellow = iec_scale(-10);
        double red = iec_scale(-5);

        double bar_range = 1.0 / (double)nb_bars;
        for (int cpt = 0; cpt < nb_bars; ++cpt) {
            double bar_percent = double.min(1.0, double.max (0.0, m_value - (bar_range * cpt)) / bar_range);
            double bar_x = 0, bar_y = 0;
            if (orientation == Gtk.Orientation.VERTICAL) {
                bar_x = (cpt * (bar_width + space));
                bar_y = 0;
            } else {
                bar_x = 0;
                bar_y = (cpt * (bar_height + space));
            }

            m_buffer.context.set_source_rgba (0.3, 0.3, 0.3, (1.0 - bar_percent) * back_rem);
            m_buffer.context.rectangle (bar_x, bar_y, bar_width, bar_height);
            m_buffer.context.fill_preserve ();

            if ((bar_range * cpt) >= red) {
                m_buffer.context.set_source_rgba (1, 0, 0, bar_percent * remanence);
            } else if ((bar_range * cpt) >= yellow) {
                m_buffer.context.set_source_rgba (1, 0.4, 0, bar_percent * remanence);
            } else {
                m_buffer.context.set_source_rgba (0, 0.8, 0, bar_percent * remanence);
            }
            m_buffer.context.fill();
        }

        in_ctx.set_source_surface (m_buffer.surface, 0, 0);
        in_ctx.paint_with_alpha (0.8);

        return true;
    }

    public override void size_allocate (Gtk.Allocation in_allocation) {
        base.size_allocate (in_allocation);

        m_buffer = new Granite.Drawing.BufferSurface (in_allocation.width, in_allocation.height);
    }

    private bool on_tick (Gtk.Widget in_widget, Gdk.FrameClock in_frame_clock) {
        int64 current_frame = in_frame_clock.get_frame_time ();
        if (current_frame - m_last_frame > 50) {
            queue_draw ();
            m_last_frame = current_frame;
        }
        return true;
    }

    private void on_monitor_peak (float in_data) {
        double peak = iec_scale (20.0 * GLib.Math.log10(in_data * (level / 100.0)));
        if (m_value != peak) {
            m_value = peak;
        }
    }

    private void on_monitor_paused () {
        m_value = 0.0;
    }

    private double
    iec_scale (double inDB)
    {
        double def = 0.0;

        if (inDB < -70.0)
            def = 0.0;
        else if (inDB < -60.0)
            def = (inDB + 70.0) * 0.25;
        else if (inDB < -50.0)
            def = (inDB + 60.0) * 0.5 + 2.5;
        else if (inDB < -40.0)
            def = (inDB + 50.0) * 0.75 + 7.5;
        else if (inDB < -30.0)
            def = (inDB + 40.0) * 1.5 + 15.0;
        else if (inDB < -20.0)
            def = (inDB + 30.0) * 2.0 + 30.0;
        else if (inDB < 0.0)
            def = (inDB + 20.0) * 2.5 + 50.0;
        else
            def = inDB * 5.0 + 90.0;

        return def / 100.0;
    }
}