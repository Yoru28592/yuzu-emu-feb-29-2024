// SPDX-FileCopyrightText: Copyright 2020 yuzu Emulator Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include <vector>
#include <QLabel>
#include <qnamespace.h>
#include "common/settings.h"
#include "core/core.h"
#include "ui_configure_graphics_advanced.h"
#include "yuzu/configuration/configuration_shared.h"
#include "yuzu/configuration/configure_graphics_advanced.h"
#include "yuzu/configuration/shared_translation.h"
#include "yuzu/configuration/shared_widget.h"

ConfigureGraphicsAdvanced::ConfigureGraphicsAdvanced(
    const Core::System& system_, std::shared_ptr<std::vector<ConfigurationShared::Tab*>> group_,
    const ConfigurationShared::Builder& builder, QWidget* parent)
    : Tab(group_, parent), ui{std::make_unique<Ui::ConfigureGraphicsAdvanced>()}, system{system_} {

    ui->setupUi(this);
    vertex_clamping = ui->vertex_clamping;
    recompress_astc_textures = ui->recompress_astc_textures;
    shader_accuracy_mode_combobox = ui->shader_accuracy_mode_combobox;
    enable_nvidia_byte_swap_workaround = ui->enable_nvidia_byte_swap_workaround;
    opengl_disable_fast_buffer_sub_data = ui->opengl_disable_fast_buffer_sub_data;

    Setup(builder);

    // Populate Vertex Clamping ComboBox
    vertex_clamping->addItem(QStringLiteral("Disabled"),
                             QVariant::fromValue(Settings::VertexClampingMode::Disabled));
    vertex_clamping->addItem(QStringLiteral("Safe"),
                             QVariant::fromValue(Settings::VertexClampingMode::Safe));
    vertex_clamping->addItem(QStringLiteral("Aggressive"),
                             QVariant::fromValue(Settings::VertexClampingMode::Aggressive));

    // Populate Shader Accuracy ComboBox
    shader_accuracy_mode_combobox->addItem(tr("Fast (Default)"),
                                           QVariant::fromValue(Settings::ShaderAccuracyMode::Fast));
    shader_accuracy_mode_combobox->addItem(tr("Accurate"),
                                           QVariant::fromValue(Settings::ShaderAccuracyMode::Accurate));

    SetConfiguration();

    checkbox_enable_compute_pipelines->setVisible(false);
}

ConfigureGraphicsAdvanced::~ConfigureGraphicsAdvanced() = default;

void ConfigureGraphicsAdvanced::SetConfiguration() {
    // Load Vertex Clamping setting
    vertex_clamping->setCurrentIndex(vertex_clamping->findData(
        QVariant::fromValue(Settings::values.vertex_clamping_mode.GetValue())));
    // Load Recompress ASTC Textures setting
    recompress_astc_textures->setChecked(Settings::values.recompress_astc_textures.GetValue());
    // Load Shader Accuracy setting
    shader_accuracy_mode_combobox->setCurrentIndex(shader_accuracy_mode_combobox->findData(
        QVariant::fromValue(Settings::values.shader_accuracy_mode.GetValue())));
    // Load NVIDIA Byte Swap Workaround setting
    enable_nvidia_byte_swap_workaround->setChecked(Settings::values.enable_nvidia_shader_byte_swap_workaround.GetValue());
    // Load Disable Fast Buffer Sub-Data (OpenGL) setting
    opengl_disable_fast_buffer_sub_data->setChecked(Settings::values.opengl_disable_fast_buffer_sub_data.GetValue());
}

void ConfigureGraphicsAdvanced::Setup(const ConfigurationShared::Builder& builder) {
    auto& layout = *ui->populate_target->layout();
    std::map<u32, QWidget*> hold{}; // A map will sort the data for us

    for (auto setting :
         Settings::values.linkage.by_category[Settings::Category::RendererAdvanced]) {
        ConfigurationShared::Widget* widget = builder.BuildWidget(setting, apply_funcs);

        if (widget == nullptr) {
            continue;
        }
        if (!widget->Valid()) {
            widget->deleteLater();
            continue;
        }

        hold.emplace(setting->Id(), widget);

        // Keep track of enable_compute_pipelines so we can display it when needed
        if (setting->Id() == Settings::values.enable_compute_pipelines.Id()) {
            checkbox_enable_compute_pipelines = widget;
        }
    }
    for (const auto& [id, widget] : hold) {
        layout.addWidget(widget);
    }
}

void ConfigureGraphicsAdvanced::ApplyConfiguration() {
    // Save Vertex Clamping setting
    Settings::values.vertex_clamping_mode =
        vertex_clamping->currentData().value<Settings::VertexClampingMode>();
    // Save Recompress ASTC Textures setting
    Settings::values.recompress_astc_textures = recompress_astc_textures->isChecked();
    // Save Shader Accuracy setting
    Settings::values.shader_accuracy_mode =
        shader_accuracy_mode_combobox->currentData().value<Settings::ShaderAccuracyMode>();
    // Save NVIDIA Byte Swap Workaround setting
    Settings::values.enable_nvidia_shader_byte_swap_workaround = enable_nvidia_byte_swap_workaround->isChecked();
    // Save Disable Fast Buffer Sub-Data (OpenGL) setting
    Settings::values.opengl_disable_fast_buffer_sub_data = opengl_disable_fast_buffer_sub_data->isChecked();

    const bool is_powered_on = system.IsPoweredOn();
    for (const auto& func : apply_funcs) {
        func(is_powered_on);
    }
}

void ConfigureGraphicsAdvanced::changeEvent(QEvent* event) {
    if (event->type() == QEvent::LanguageChange) {
        RetranslateUI();
    }

    QWidget::changeEvent(event);
}

void ConfigureGraphicsAdvanced::RetranslateUI() {
    ui->retranslateUi(this);
}

void ConfigureGraphicsAdvanced::ExposeComputeOption() {
    checkbox_enable_compute_pipelines->setVisible(true);
}
