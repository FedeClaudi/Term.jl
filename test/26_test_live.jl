using Term.LiveWidgets
import Term.LiveWidgets:
    ArrowDown,
    ArrowUp,
    ArrowLeft,
    ArrowRight,
    DelKey,
    HomeKey,
    EndKey,
    PageUpKey,
    PageDownKey,
    Enter,
    SpaceBar,
    Esc,
    Del

import Term.LiveWidgets:
    newline,
    addspace,
    del,
    addchar,
    WidgetInternals,
    PlaceHolderWidget,
    menu_activate_next,
    menu_return_value,
    multi_select_toggle,
    next_page,
    next_line,
    prev_page,
    prev_line,
    home,
    toend,
    activate_next_widget,
    activate_prev_widget,
    AppInternals,
    toggle_help,
    get_active,
    on_layout_change

import Term.Compositors: Compositor
import Term.Consoles: Console, enable, disable
import Term: Measure, AbstractRenderable

import OrderedCollections: OrderedDict

# ---------------------------------------------------------------------------- #
#                                 basic widgets                                #
# ---------------------------------------------------------------------------- #

@testset "WidgetInternals" begin
    w = TextWidget("a")

    @test w.internals.active isa Bool
    @test w.internals.measure isa Measure
    @test isnothing(w.internals.on_draw)
    @test w.internals.on_activated isa Function
    @test w.internals.on_deactivated isa Function
end

@testset "TextWidget" begin
    texts = ["test", "This is  long test"^25]
    panel = [true, false]

    for (i, t) in enumerate(texts), (j, p) in enumerate(panel)
        widget = TextWidget(t; as_panel = p)
        asframe = frame(widget)

        IS_WIN || @compare_to_string(asframe, "widget_text_$(i)_$(j)")

        @test asframe isa AbstractRenderable
        @test widget.controls isa AbstractDict
        @test widget.internals isa WidgetInternals
    end
end

@testset "InputBox" begin
    ib = InputBox()

    @test isnothing(ib.input_text)
    addchar(ib, 'a')
    addchar(ib, 'b')
    del(ib, Del())
    addspace(ib, SpaceBar())
    newline(ib, Enter())
    addchar(ib, 'c')

    @test ib.input_text == "a \nc"
    @test ib.controls isa AbstractDict
    @test ib.internals isa WidgetInternals
    @test ib.internals.measure == Measure(5, 80)

    as_frame = frame(ib)
    @test as_frame isa AbstractRenderable
    IS_WIN || @compare_to_string as_frame "widget_inputbox"
end

@testset "PlaceHolderWidget" begin
    ph = PlaceHolderWidget(5, 20, "test", "red")

    @test ph.controls isa AbstractDict
    @test ph.internals isa WidgetInternals
    @test ph.internals.measure == Measure(5, 20)

    as_frame = frame(ph)
    @test as_frame isa AbstractRenderable
    IS_WIN || @compare_to_string as_frame "widget_placeholder"
end

# ---------------------------------------------------------------------------- #
#                                     MENU                                     #
# ---------------------------------------------------------------------------- #

@testset "SimpleMenu" begin
    for (i, w) in enumerate((50, 100))
        for (j, orientation) in enumerate((:vertical, :horizontal))
            for (k, style) in enumerate(("red", "green"))
                mn = SimpleMenu(
                    ["one", "two", "three"];
                    width = w,
                    layout = orientation,
                    active_style = style,
                    inactive_style = "dim",
                )

                @test mn.controls isa AbstractDict
                @test mn.internals isa WidgetInternals

                # if orientation != :vertical
                #     @test mn.internals.measure == Measure(3, w)
                # else
                #     @test mn.internals.measure == Measure(w, 3)
                # end

                IS_WIN || @compare_to_string frame(mn) "widget_simplemenu_$(i)_$(j)_$(k)"

                menu_activate_next(mn, 1)
                IS_WIN || @compare_to_string frame(mn) "widget_simplemenu_$(i)_$(j)_$(k)_b"

                @test menu_return_value(mn, Enter()) == 2
            end
        end
    end
end

@testset "ButtonsMenu" begin
    for (i, w) in enumerate((50, 100))
        for (j, orientation) in enumerate((:vertical, :horizontal))
            for (k, style) in enumerate(("red", "green"))
                for (l, height) in enumerate((5, 10))
                    mn = ButtonsMenu(
                        ["one", "two", "three"];
                        width = w,
                        layout = orientation,
                        active_style = style,
                        inactive_style = "dim",
                        height = height,
                    )

                    @test mn.controls isa AbstractDict
                    @test mn.internals isa WidgetInternals

                    # if orientation == :vertical
                    #     @test mn.internals.measure == Measure(height, w)
                    # else
                    #     @test mn.internals.measure == Measure(w, height)
                    # end

                    IS_WIN ||
                        @compare_to_string frame(mn) "widget_buttonsmenu_$(i)_$(j)_$(k)_($l)"

                    menu_activate_next(mn, 1)
                    IS_WIN ||
                        @compare_to_string frame(mn) "widget_buttonsmenu_$(i)_$(j)_$(k)_$(l)_b"

                    @test menu_return_value(mn, Enter()) == 2
                end
            end
        end
    end
end

@testset "MultiSelectMenu" begin
    for (i, w) in enumerate((50, 100))
        for (k, style) in enumerate(("red", "green"))
            mn = MultiSelectMenu(
                ["one", "two", "three"];
                width = w,
                active_style = style,
                inactive_style = "dim",
            )

            @test mn.controls isa AbstractDict
            @test mn.internals isa WidgetInternals
            @test mn.internals.measure == Measure(3, w)

            IS_WIN || @compare_to_string frame(mn) "widget_multiselectmenu_$(i)_$(k)"

            menu_activate_next(mn, 1)
            IS_WIN || @compare_to_string frame(mn) "widget_multiselectmenu_$(i)_$(k)_b"

            multi_select_toggle(mn, SpaceBar())
            @test menu_return_value(mn, Enter()) == [2]
        end
    end
end

# ---------------------------------------------------------------------------- #
#                                Pager & Gallery                               #
# ---------------------------------------------------------------------------- #

@testset "Pager" begin
    txt =
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor\nincididunt ut labore et dolore magna aliqua.\nUt enim ad minim veniam, quis nostrud exercitation\nullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in\nvoluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserun\n mollit anim id est laborum."^5

    for (i, w) in enumerate((30, 60))
        for (j, h) in enumerate((20, 40))
            for (k, ln) in enumerate((true, false))
                pag = Pager(txt; width = w, height = h, line_numbers = ln, title = "test")

                @test pag.controls isa AbstractDict
                @test pag.internals isa WidgetInternals
                @test pag.internals.measure == Measure(h, w)
                @test pag.content isa Vector{String}

                LiveWidgets.prev_line(pag, 'a')
                LiveWidgets.next_line(pag, 'a')
                LiveWidgets.prev_line(pag, 'a')
                next_page(pag, 'a')
                prev_page(pag, 'a')
                next_page(pag, 'a')

                home(pag, HomeKey())
                toend(pag, EndKey())
                prev_page(pag, ArrowLeft())

                IS_WIN || @compare_to_string frame(pag) "widget_pager_$(i)_$(j)_$(k)"
            end
        end
    end
end

@testset "Gallery" begin
    for (i, w) in enumerate((56, 80))
        for (j, h) in enumerate((20, 40))
            for (k, sp) in enumerate((true, false))
                gal = Gallery(
                    [TextWidget("aaa"), Pager("aaa" .^ 200)];
                    height = h,
                    width = w,
                    show_panel = sp,
                )

                @test gal.internals isa WidgetInternals
                @test gal.controls isa AbstractDict
                @test gal.widgets isa Vector

                IS_WIN || @compare_to_string frame(gal) "widget_gal_$(i)_$(j)_$(k)"

                activate_prev_widget(gal, 1)
                activate_next_widget(gal, 1)
                activate_next_widget(gal, 1)

                IS_WIN || @compare_to_string frame(gal) "widget_gal_$(i)_$(j)_$(k)_b"

                @test get_active(gal) isa AbstractWidget
            end
        end
    end
end

# ---------------------------------------------------------------------------- #
#                                      APP                                     #
# ---------------------------------------------------------------------------- #

@testset "App Layout Only" begin
    layout = :((r(10, 0.5) * g(10, 0.5)) / b(10, 1.0))

    for (j, h) in enumerate((20, 40))
        for (k, e) in enumerate((true, false))
            app = App(
                layout;
                height = h,
                expand = e,
                help_message = """
                This is just an example of how to create a simple app without any specific content.

                !!! note
                    You can make apps too!
                """,
            )

            @test app.internals isa AppInternals
            @test app.measure isa Measure
            @test app.controls isa AbstractDict
            @test app.widgets isa AbstractDict
            @test app.compositor isa Compositor

            IS_WIN || @compare_to_string frame(app) "single_widghet_app_$(j)_$(k)"

            IS_WIN ||
                @compare_to_string sprint(print, app) "single_widghet_app_$(j)_$(k)_print"

            toggle_help(app)
            IS_WIN || @compare_to_string frame(app) "single_widghet_app_$(j)_$(k)_help"
            toggle_help(app)
            IS_WIN || @compare_to_string frame(app) "single_widghet_app_$(j)_$(k)_nohelp"

            sleep(1)
        end
    end
end

@testset "App Single Widget" begin
    for (i, w) in enumerate((0.5, 20))
        for (j, h) in enumerate((20, 40))
            for (k, e) in enumerate((true, false))
                app = App(TextWidget("a"^100); width = w, height = h, expand = e)

                @test app.internals isa AppInternals
                @test app.measure isa Measure
                @test app.controls isa AbstractDict
                @test app.widgets isa AbstractDict
                @test app.compositor isa Compositor

                # IS_WIN || @compare_to_string frame(app) "app_single_widget_$(i)_$(j)_$(k)"

                # IS_WIN ||
                #     @compare_to_string sprint(print, app) "app_single_widget_$(i)_$(j)_$(k)_print"

                # toggle_help(app)
                # IS_WIN ||
                #     @compare_to_string frame(app) "app_single_widget_$(i)_$(j)_$(k)_help"
                # toggle_help(app)
                # IS_WIN ||
                #     @compare_to_string frame(app) "app_single_widget_$(i)_$(j)_$(k)_nohelp"

                # c1, c2 = Console(30), Console(90)

                # for (m, c) in enumerate((c1, c2, c1))
                #     enable(c)
                #     on_layout_change(app)
                #     # IS_WIN ||
                #     #     @compare_to_string frame(app) "app_single_widget_$(i)_$(j)_$(k)_$(m)"
                #     disable(c)
                # end

                sleep(1)
            end
        end
    end
end

@testset "App complete" begin
    rgb_visualizer = TextWidget("")

    R = InputBox(title = "R value", style = "red", title_justify = :center)
    G = InputBox(title = "G value", style = "green", title_justify = :center)
    B = InputBox(title = "B value", style = "blue", title_justify = :center)

    button = Button("random"; color = "light_slate_grey", text_color = "white")

    widgets = OrderedDict{Symbol,AbstractWidget}(
        :A => rgb_visualizer,
        :R => R,
        :G => G,
        :B => B,
        :b => button,
    )

    layout = :(A(22, 0.4) * (R(6, 0.6) / G(6, 0.6) / B(6, 0.6) / b(4, 0.6)))
    app = App(layout; widgets = widgets)

    # IS_WIN || @compare_to_string frame(app) "app_complete"

    # c1, c2 = Console(30), Console(90)

    # for (m, c) in enumerate((c1, c2, c1))
    #     enable(c)
    #     on_layout_change(app)
    #     # IS_WIN || @compare_to_string frame(app) "app_complete_$(m)"
    #     disable(c)
    # end

    # sleep(1)
end
