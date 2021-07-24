import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { OrderRoutingModule } from './order-routing.module';
import { OrderManagerComponent } from './order-manager/order-manager.component';
import { OrderDetailComponent } from './order-detail/order-detail.component';
import { ReceivedOrderRegistryComponent } from './received-order-registry/received-order-registry.component';
import { OrderComponent } from './order.component';
import { TableModule } from 'primeng/table';
import { DropdownModule } from 'primeng/dropdown';
import { ButtonModule } from 'primeng/button';
import { ToastModule } from 'primeng/toast';
import { DialogModule } from 'primeng/dialog';
import { FormsModule } from '@angular/forms';
import { CheckboxModule } from 'primeng/checkbox';
import { TabViewModule } from 'primeng/tabview';
import { MultiSelectModule } from 'primeng/multiselect';
import { TabMenuModule } from 'primeng/tabmenu';
import { DeliverComponent } from './deliver/deliver.component';
import { BooksListByStudentComponent } from './deliver/books-list-by-student/books-list-by-student.component';
import { OrderConsultComponent } from './order-consult/order-consult.component';
import { InputTextModule } from 'primeng/inputtext';
import { ConfirmDialogModule } from 'primeng/confirmdialog';
import { DeleteConfirmDialogComponent } from '../delete-confirm-dialog/delete-confirm-dialog.component';
import { DeleteOrderDialogComponent } from './delete-order-dialog/delete-order-dialog.component';

@NgModule({
  imports: [
    InputTextModule,
    CommonModule,
    OrderRoutingModule,
    TableModule,
    DropdownModule,
    ButtonModule,
    ToastModule,
    DialogModule,
    FormsModule,
    CheckboxModule,
    TabViewModule,
    MultiSelectModule,
    TabMenuModule,
    ConfirmDialogModule
  ],
  declarations: [OrderManagerComponent, OrderDetailComponent, ReceivedOrderRegistryComponent, OrderComponent, DeliverComponent, BooksListByStudentComponent, OrderConsultComponent, DeleteOrderDialogComponent],
})
export class OrderModule { }
