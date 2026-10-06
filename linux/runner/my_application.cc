#include "my_application.h"
#include <flutter_linux/flutter_linux.h>

struct _MyApplication { GtkApplication parent_instance; };
G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static void my_application_activate(GApplication* application) {
  GtkWindow* window = GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
  gtk_window_set_title(window, "Milk Tracker");
  gtk_window_set_default_size(window, 800, 600);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  GtkWidget* view = fl_view_new(project);
  gtk_widget_show(view);
  gtk_container_add(GTK_CONTAINER(window), view);
  gtk_widget_show(GTK_WIDGET(window));
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  return MY_APPLICATION(g_object_new(my_application_get_type(),
      "application-id", "se.rickard.milktracker",
      "flags", G_APPLICATION_NON_UNIQUE, nullptr));
}
