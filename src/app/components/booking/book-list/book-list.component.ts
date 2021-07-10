import { Component, OnInit, OnChanges, SimpleChanges, Input } from '@angular/core';
import { ClassesService } from 'src/app/services/classes.service';
import { BookingDetailComponent } from 'src/app/components/booking/booking-detail/booking-detail.component';
import { Utils } from 'src/app/util/utils';
import { utils } from 'protractor';
import { BookingComponent } from '../booking.component';

@Component({
  selector: 'app-book-list',
  templateUrl: './book-list.component.html',
  styleUrls: ['./book-list.component.css']
})
export class BookListComponent implements OnChanges {
  @Input() classId: number;
  public bookList: any[];
  public selectedBooks: any[];
  private utils: Utils = new Utils();

  constructor(private classService: ClassesService,
    private bookingDetailComponent: BookingDetailComponent,
    private bookingComponent: BookingComponent) { }
  ngOnChanges(changes: SimpleChanges): void {
    if (changes['classId'] && changes['classId'].currentValue != null) {
      this.loadBookListByClass(changes['classId'].currentValue);
      this.selectedBooks = [];
    }
  }

  private loadBookListByClass(id: number): void {
    this.classService.getBookAssociationByClassId(id)
      .subscribe(
        res => this.bookList = res
      );
  }

  save(): void {
    this.bookingDetailComponent.booksToBeBooked = this.selectedBooks;
    if (!this.bookingDetailComponent.bookingId) {
      this.bookingDetailComponent.bookingInfo = {
        data: new Date(),
        caparra: 0
      };
    }
    this.bookingDetailComponent.displayBookList = false;
  }

}
