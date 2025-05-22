// SPDX-FileCopyrightText: Copyright 2020 yuzu Emulator Project
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <memory>
#include <vector>
#include <QWidget>
#include "yuzu/configuration/configuration_shared.h"

namespace Core {
class System;
}

namespace Ui {
class ConfigureGraphicsAdvanced;
}

namespace ConfigurationShared {
class Builder;
}

class ConfigureGraphicsAdvanced : public ConfigurationShared::Tab {
    Q_OBJECT

public:
    explicit ConfigureGraphicsAdvanced(
        const Core::System& system_, std::shared_ptr<std::vector<ConfigurationShared::Tab*>> group,
        const ConfigurationShared::Builder& builder, QWidget* parent = nullptr);
    ~ConfigureGraphicsAdvanced() override;

    void ApplyConfiguration() override;
    void SetConfiguration() override;

    void ExposeComputeOption();

private:
    void Setup(const ConfigurationShared::Builder& builder);
    void changeEvent(QEvent* event) override;
    void RetranslateUI();

    std::unique_ptr<Ui::ConfigureGraphicsAdvanced> ui;
    QComboBox* vertex_clamping;
    QCheckBox* recompress_astc_textures;
    QComboBox* shader_accuracy_mode_combobox;
    QCheckBox* enable_nvidia_byte_swap_workaround;
    QCheckBox* opengl_disable_fast_buffer_sub_data;

    const Core::System& system;

    std::vector<std::function<void(bool)>> apply_funcs;

    QWidget* checkbox_enable_compute_pipelines{};
};
