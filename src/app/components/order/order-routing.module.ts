import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { ReceivedOrderRegistryComponent } from './received-order-registry/received-order-registry.component';
import { OrderDetailComponent } from './order-detail/order-detail.component';
import { OrderManagerComponent } from './order-manager/order-manager.component';
import { OrderComponent } from './order.component';
import { DeliverComponent } from './deliver/deliver.component';
import { StudentDetailComponent } from '../student/student-detail/student-detail.component';
import { StudentsForClassComponent } from '../students-for-class/students-for-class.component';

const routes: Routes = [

  {
    path: 'order',
    component: OrderComponent,
    children: [
      { path: '', redirectTo: 'list', pathMatch: 'full' },
      {
        path: 'list',
        component: OrderManagerComponent
      },
      {
        path: 'new',
        component: OrderDetailComponent
      },
      {
        path: 'arrival',
        component: ReceivedOrderRegistryComponent
      },
      {
        path: 'deliver',
        component: DeliverComponent
      }
    ]
  },



];


@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class OrderRoutingModule { }
