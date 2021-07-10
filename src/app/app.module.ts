import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import { HttpClientModule } from '@angular/common/http';
import { AppComponent } from './app.component';
import { TableModule } from 'primeng/table';
import { Routes, RouterModule } from '@angular/router';
import { BookService } from './services/book.service';
import { MenuModule } from 'primeng/menu';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { BookDetailComponent } from './components/books/book-detail/book-detail.component';
import { PublisherService } from './services/publisher.service';
import { BookComponent } from './components/books/book.component';
import { InputTextModule } from 'primeng/inputtext';
import { DropdownModule } from 'primeng/dropdown';
import { ButtonModule } from 'primeng/button';
import { ToastModule } from 'primeng/toast';
import { MessageService } from 'primeng/components/common/messageservice';
import { DialogModule } from 'primeng/dialog';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { MenuComponent } from './components/menu/menu.component';
import { PublisherComponent } from './components/publisher/publisher.component';
import { PublisherDetailComponent } from './components/publisher/publisher-detail/publisher-detail.component';
import { InputMaskModule } from 'primeng/inputmask';
import { SchoolComponent } from './components/school/school.component';
import { SchoolDetailComponent } from './components/school/school-detail/school-detail.component';
import { SchoolService } from './services/school.service';
import { ClassesService } from './services/classes.service';
import { ClassComponent } from './components/class/class.component';
import { ClassDetailComponent } from './components/class/class-detail/class-detail.component';
import { BookAssociationComponent } from './components/class/book-association/book-association.component';
import { PickListModule } from 'primeng/picklist';
import { StudentComponent } from './components/student/student.component';
import { StudentDetailComponent } from './components/student/student-detail/student-detail.component';
import { BookingComponent } from './components/booking/booking.component';
import { BookingDetailComponent } from './components/booking/booking-detail/booking-detail.component';
import { BookListComponent } from './components/booking/book-list/book-list.component';
import { CheckboxModule } from 'primeng/checkbox';
import { BookingService } from './services/booking.service';
import { WholesalersComponent } from './components/wholesalers/wholesalers.component';
import { WholesalerDetailComponent } from './components/wholesalers/wholesaer-detail/wholesaler-detail.component';
import { TabViewModule } from 'primeng/tabview';
import { ConfirmDialogModule } from 'primeng/confirmdialog';
import { ConfirmationService } from 'primeng/api';
import { OrderService } from './services/order.service';
import { WholesalerService } from './services/wholesaler.service';
import { MultiSelectModule } from 'primeng/multiselect';
import { OrderModule } from './components/order/order.module';
import { TabMenuModule } from 'primeng/tabmenu';
import { InputTextareaModule } from 'primeng/inputtextarea';
import { TooltipModule } from 'primeng/tooltip';
import { ReminderComponent } from './components/reminder/reminder.component';
import { StudentsForClassComponent } from './components/students-for-class/students-for-class.component';
import { DeleteConfirmDialogComponent } from './components/delete-confirm-dialog/delete-confirm-dialog.component';




export const routes: Routes = [
  { path: 'book', component: BookComponent },
  { path: 'wholesaler', component: WholesalersComponent },
  { path: 'publisher', component: PublisherComponent },
  { path: 'school', component: SchoolComponent },
  { path: 'class', component: ClassComponent },
  { path: 'student', component: StudentComponent },
  { path: 'booking', component: BookingComponent },
  { path: 'remind', component: ReminderComponent },
  { path: 'order', loadChildren: './components/order/order.module#OrderModule' },
  { path: 'student-detail', component: StudentsForClassComponent },
  { path: '', redirectTo: '/booking', pathMatch: 'full' }
];

@NgModule({
  declarations: [
    AppComponent,
    BookComponent,
    MenuComponent,
    BookDetailComponent,
    PublisherComponent,
    PublisherDetailComponent,
    SchoolComponent,
    SchoolDetailComponent,
    ClassComponent,
    ClassDetailComponent,
    BookAssociationComponent,
    StudentComponent,
    StudentDetailComponent,
    BookingComponent,
    BookingDetailComponent,
    BookListComponent,
    WholesalersComponent,
    WholesalerDetailComponent,
    ReminderComponent,
    StudentsForClassComponent,
    DeleteConfirmDialogComponent
  ],
  imports: [
    BrowserModule,
    BrowserAnimationsModule,
    HttpClientModule,
    RouterModule.forRoot(routes, { useHash: true }),
    TableModule,
    MenuModule,
    InputTextModule,
    DropdownModule,
    ButtonModule,
    ToastModule,
    DialogModule,
    FormsModule,
    InputMaskModule,
    PickListModule,
    CheckboxModule,
    TabViewModule,
    ConfirmDialogModule,
    MultiSelectModule,
    OrderModule,
    TabMenuModule,
    InputTextareaModule,
    TooltipModule
  ],
  providers: [
    BookService,
    PublisherService,
    MessageService,
    SchoolService,
    ClassesService,
    BookingService,
    OrderService,
    WholesalerService,
    ConfirmationService
  ],
  bootstrap: [AppComponent],
  entryComponents: [PublisherDetailComponent,
    ClassDetailComponent, BookAssociationComponent,
    StudentDetailComponent,
    BookingComponent, BookingDetailComponent, BookListComponent,DeleteConfirmDialogComponent]
})
export class AppModule { }
