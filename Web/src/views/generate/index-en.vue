<template>
    <div class="dashboard-container">
        <div class="back">
            <div class="content">
                <div class="reminder">Activities</div>
                <div
                    class="pick"
                    v-for="(fitem, findex) in activity"
                    :label="fitem"
                    :key="findex"
                >
                    <el-checkbox
                        class="activityname"
                        v-model="ifActivity[fitem.num]"
                        @change="setactivity($event, fitem)"
                        >{{ fitem.desc }}</el-checkbox
                    >
                    <div class="reminder3">Triggered by:</div>
                    <el-checkbox-group
                        v-model="fitem.actor"
                        @change="setactor($event, findex)"
                        size="small"
                    >
                        <el-checkbox-button
                            v-model="fitem.actor"
                            @change="setactorAll($event, findex)"
                            class="checkOperator"
                            >All</el-checkbox-button
                        >
                        <el-checkbox-button
                            class="checkOperator"
                            v-for="(item, index) in actor"
                            :label="item"
                            :key="index"
                            >{{ item.desc }}</el-checkbox-button
                        >
                    </el-checkbox-group>

                    <div class="reminder3">Triggered after: (pre-state)</div>

                    <el-checkbox-group
                        v-model="fitem.pre_state"
                        @change="setprestate($event, findex)"
                        size="small"
                    >
                        <el-checkbox-button
                            class="checkOperator"
                            v-for="(item, index) in pre_state"
                            :label="item"
                            :key="index"
                            >{{ item.desc }}</el-checkbox-button
                        >
                    </el-checkbox-group>

                    <div class="reminder3">Function:</div>

                    <prism-editor
                        class="function-editor"
                        v-model.trim="fitem.text"
                        :line-numbers="true"
                        :tabSize="4"
                        :highlight="highlighter"
                    >
                    </prism-editor>
                </div>
                <div class="reminder2">MariSmart Application</div>

                <el-button
                    type="primary"
                    class="checkbutton1"
                    @click="update"
                    v-loading.fullscreen.lock="loading"
                >
                    Generate <i class="el-icon-refresh-right"></i>
                </el-button>
                <el-button
                    type="primary"
                    class="checkbutton2"
                    @click="goVerify"
                    v-loading.fullscreen.lock="loading"
                >
                    Verification View <i class="el-icon-right"></i>
                </el-button>
                <prism-editor
                    class="my-editor"
                    v-model.trim="code"
                    :line-numbers="true"
                    :tabSize="4"
                    :highlight="highlighter"
                >
                </prism-editor>
            </div>
        </div>
    </div>
</template>
<script>
import { PrismEditor } from "vue-prism-editor";
import "vue-prism-editor/dist/prismeditor.min.css";

import { highlight, languages } from "prismjs";
import "prismjs/components/prism-clike.min";
import "prismjs/components/prism-solidity.min";
import "prismjs/themes/prism-dark.css";

// import IoT from '@/assets/cases/IoT.txt';

export default {
    name: "generate",
    components: {
        PrismEditor,
    },
    data() {
        return {
            actor: [
                {
                    desc: "Shipper",
                    num: 1,
                    name: "shipper",
                },
                {
                    desc: "Carrier",
                    num: 2,
                    name: "carrier",
                },
                {
                    desc: "Consignee",
                    num: 3,
                    name: "consignee",
                },
                {
                    desc: "Inspector",
                    num: 4,
                    name: "pre_shipment_inspector",
                },
                {
                    desc: "Export Port",
                    num: 5,
                    name: "export_port_operator",
                },
                {
                    desc: "Import Port",
                    num: 6,
                    name: "import_port_operator",
                },
            ],
            ifActivity: [],
            activity: [
                {
                    desc: "Create",
                    num: 1,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "create",
                },
                {
                    desc: "Sign",
                    num: 2,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "sign",
                },
                {
                    desc: "Inspect",
                    num: 3,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "inspect",
                },
                {
                    desc: "Export",
                    num: 4,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "exportShipment",
                },
                {
                    desc: "Cancel",
                    num: 5,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "cancel",
                },
                {
                    desc: "Depart",
                    num: 6,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "depart",
                },
                {
                    desc: "Report Loss",
                    num: 7,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "reportLoss",
                },
                {
                    desc: "Report Damage",
                    num: 8,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "reportDamage",
                },
                {
                    desc: "Arrive",
                    num: 9,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "arrive",
                },
                {
                    desc: "Import",
                    num: 10,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "importShipment",
                },
                {
                    desc: "Rearrange",
                    num: 11,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "rearrange",
                },
                {
                    desc: "Receive",
                    num: 12,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "receiveShipment",
                },
                {
                    desc: "Claim for Compensation",
                    num: 13,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "claim",
                },
                {
                    desc: "Pay for Compensation",
                    num: 14,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "compensate",
                },
                {
                    desc: "Close",
                    num: 15,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "close",
                },
            ],
            pre_state: [
                {
                    desc: "created",
                    num: 1,
                    name: "created",
                },
                {
                    desc: "signed",
                    num: 2,
                    name: "signed",
                },
                {
                    desc: "inspected",
                    num: 3,
                    name: "inspected",
                },
                {
                    desc: "exported",
                    num: 4,
                    name: "exported",
                },
                {
                    desc: "departed",
                    num: 5,
                    name: "departed",
                },
                {
                    desc: "lost",
                    num: 6,
                    name: "lost",
                },
                {
                    desc: "arrived",
                    num: 7,
                    name: "arrived",
                },
                {
                    desc: "imported",
                    num: 8,
                    name: "imported",
                },
                {
                    desc: "rearranged",
                    num: 9,
                    name: "rearranged",
                },
                {
                    desc: "received",
                    num: 10,
                    name: "received",
                },
                {
                    desc: "claimed",
                    num: 11,
                    name: "claimed",
                },
                {
                    desc: "closed",
                    num: 12,
                    name: "closed",
                },
            ],
            code: "",
            activityList: [],
            loading: false,
            fileIndex: 0,
            readonly: false,
        };
    },
    methods: {
        highlighter(code) {
            return highlight(code, languages.sol, "sol");
        },
        readFile(name) {
            let xhr = new XMLHttpRequest();
            xhr.open("GET", "/static/" + name + ".txt", false);
            xhr.overrideMimeType("text/html;charset=utf-8");
            xhr.send(null);
            return xhr.responseText;
        },
        setactorAll(val, index) {
            this.activity[index].actor = val ? this.actor : [];
            this.isIndeterminate1 = false;
        },
        setactivity(val, item) {
            let checkedCount = val.length;
            item.text = this.readFile(item.name);
        },
        setactor(val, index) {
            let checkedCount = val.length;
        },
        setprestate(val, index) {
            let checkedCount = val.length;
        },
        goVerify() {
            this.$router.push({
                name: "dashboard-en",
                params: { code: this.code },
            });
        },
        update() {
            // check if activity is empty
            let flag = false;
            for (let i = 0; i < this.ifActivity.length; i++) {
                if (this.ifActivity[i]) {
                    flag = true;
                }
            }
            if (!flag) {
                this.$message.error("Please select at least one activity!");
                return;
            }
            for (let i = 0; i < this.activity.length; i++) {
                if (
                    this.activity[i].actor.length == 0 &&
                    this.ifActivity[this.activity[i].num]
                ) {
                    this.$message.error(
                        `Please assign at least one stakeholder for ${this.activity[i].desc}!`
                    );
                    return;
                }
                if (
                    this.activity[i].pre_state.length == 0 &&
                    this.ifActivity[this.activity[i].num] &&
                    this.activity[i].num != 1
                ) {
                    this.$message.error(
                        `Please assign at least one pre-state for ${this.activity[i].desc}!`
                    );
                    return;
                }
            }

            this.loading = true;
            // generate code
            let origin = this.readFile("module");
            let activityList = ["", "", "", "", "", ""];
            let modifier = "";
            for (let i = 0; i < this.activity.length; i++) {
                if (!this.ifActivity[this.activity[i].num]) {
                    continue;
                }
                let actor_stmt = "";
                for (let j = 0; j < this.activity[i].actor.length; j++) {
                    if (this.activity[i].actor[j]) {
                        actor_stmt += ` msg.sender == ${this.activity[i].actor[j].name} ||`;
                    }
                }
                actor_stmt = actor_stmt.substring(0, actor_stmt.length - 2);
                actor_stmt = `\t\trequire(${actor_stmt});\n`;

                let pre_state_stmt = "";
                for (let j = 0; j < this.activity[i].pre_state.length; j++) {
                    if (this.activity[i].pre_state[j]) {
                        pre_state_stmt += ` state == ${this.activity[i].pre_state[j].name} ||`;
                    }
                }
                pre_state_stmt = pre_state_stmt.substring(
                    0,
                    pre_state_stmt.length - 2
                );
                pre_state_stmt = `\t\trequire(${pre_state_stmt});\n`;

                modifier += `\tmodifier pre_${this.activity[i].name} override () {\n${actor_stmt}${pre_state_stmt}\t\t_;\n\t}\n\n`;

                for (let j = 0; j < this.activity[i].actor.length; j++) {
                    if (this.activity[i].actor[j]) {
                        activityList[this.activity[i].actor[j].num - 1] +=
                            this.activity[i].text + `\n`;
                    }
                }
            }
            origin = origin.replace("MODIFIER", modifier);
            for (let i = 0; i < activityList.length; i++) {
                origin = origin.replace(
                    `${this.actor[i].name}_function`,
                    activityList[i]
                );
            }
            this.loading = false;
            this.code = origin;
            return;
        },
    },
};
</script>
<style scoped lang="scss">
/* required class */
.my-editor {
    background: #2d2d2d;
    color: #ccc;
    font-family: Fira code, Fira Mono, Consolas, Menlo, Courier, monospace;
    font-size: 14px;
    line-height: 1.5;
    padding-top: 15px;

    height: 1300px;
    border-radius: 5px;
    top: 70px;
    left: 630px;
    right: 15px;
    width: auto;
    position: absolute;
}
.function-editor {
    background: #2d2d2d;
    color: #ccc;
    font-family: Fira code, Fira Mono, Consolas, Menlo, Courier, monospace;
    font-size: 14px;
    border-radius: 5px;
    position: relative;
    padding: 10px;
    margin: 10px;
    height: auto;
}
.prism-editor__textarea:focus {
    outline: none;
}
.content {
    left: 10px;
    right: 10px;
    top: 70px;
    height: 1390px;
    position: absolute;
    border-radius: 10px;
    background-color: #f9fafb;
    box-shadow: 0px 0px 10px 10px #eff1f3;
}
.back {
    background-color: #f9fafb;
    height: 1460px;
}
.pick {
    height: auto;
    border-radius: 5px;
    background-color: white;
    position: relative;
    left: 15px;
    top: 70px;
    width: 600px;
    padding: 10px;
    padding-top: 20px;
    box-shadow: 0px 0px 2px 2px #eff1f3;
}
.el-checkbox__label {
    display: inline-grid;
    white-space: pre-line;
    margin-right: 30px;
    word-wrap: break-word;
    width: 400px;
}
.el-checkbox {
    color: #333333 !important;
}
.checkbox {
    font-size: 20px;
    left: 10px;
}
.reminder {
    font-size: 20px;
    position: absolute;
    top: 25px;
    left: 20px;
    color: #575c66 !important;
    font-weight: 500;
}

.reminder2 {
    font-size: 20px;
    position: absolute;
    top: 25px;
    left: 635px;
    color: #575c66;
    font-weight: 500;
}
.reminder3 {
    font-size: 14px;
    position: relative;
    top: 10px;
    left: 20px;
    color: #818998;
    line-height: 30px;
}
.classes {
    font-size: 14px;
    font-weight: bold;
    color: #818998;
    left: 25px;
    height: 50px;
    position: relative;
    line-height: 0px;
}
.activityname {
    font-size: 14px;
    font-weight: bold;
    color: #818998;
    left: 0px;
    height: 15px;
    position: relative;
    line-height: 0px;
}
.checkbutton1 {
    font-size: 20px;
    right: 255px;
    position: absolute;
    font-weight: bold;
    top: 15px;
}
.checkbutton2 {
    font-size: 20px;
    right: 20px;
    position: absolute;
    font-weight: bold;
    top: 15px;
}
.addpropbutton {
    font-size: 14px;
    font-weight: bold;
    max-width: 63px;
    max-height: 23px;
    display: flex;
    justify-content: center;
    align-items: center;
    position: relative;
    top: -10px;
}
.diytable {
    top: -10px;
    position: relative;
}
.checkOperator {
    position: relative;
    top: 10px;
    left: 20px;
    size: 14px;
}
.filepicker {
    position: absolute;
    top: 20px;
    left: 880px;
}
.filepickerbutton {
    font-size: 18px;
    font-weight: bold;
}
.proptip {
    top: 5px;
    position: relative;
    border: 0;
    font-size: 17px;
    width: 17px;
    height: 17px;
    display: flex;
    justify-content: center;
    align-items: center;
    background-color: white;
}
</style>
